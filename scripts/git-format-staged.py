#!/usr/bin/env python
#
# Git command to transform staged files according to a command that accepts file
# content on stdin and produces output on stdout. This command is useful in
# combination with `git add -p` which allows you to stage specific changes in
# a file. This command runs a formatter on the file with staged changes while
# ignoring unstaged changes.
#
# Usage: git-format-staged [OPTION]... [FILE]...
# Example: git-format-staged --formatter 'prettier --stdin-filepath "{}"' '*.js'
#
# Tested with Python 3.6 and Python 2.7.
#
# Original author: Jesse Hallett <jesse@sitr.us>

from __future__ import print_function
import argparse
from fnmatch import fnmatch
from gettext import gettext as _
import os
import re
import subprocess
import sys

# The string $VERSION is replaced during the publish process.
VERSION = '$VERSION'
PROG = sys.argv[0]

def info(msg):
    print(msg, file=sys.stderr)

def warn(msg):
    print('{}: warning: {}'.format(PROG, msg), file=sys.stderr)

def fatal(msg):
    print('{}: error: {}'.format(PROG, msg), file=sys.stderr)
    exit(1)

def format_staged_files(file_patterns, formatter, git_root, update_working_tree=True, write=True):
    try:
        output = subprocess.check_output([
            'git', 'diff-index',
            '--cached',
            '--diff-filter=AM', # select only file additions and modifications
            '--no-renames',
            'HEAD'
            ])
        for line in output.splitlines():
            entry = parse_diff(line.decode('utf-8'))
            entry_path = normalize_path(entry['src_path'], relative_to=git_root)
            if entry['dst_mode'] == '120000':
                # Do not process symlinks
                continue
            if not (matches_some_path(file_patterns, entry_path)):
                continue
            if format_file_in_index(formatter, entry, update_working_tree=update_working_tree, write=write):
                info('Reformatted {} with {}'.format(entry['src_path'], formatter))
    except Exception as err:
        fatal(str(err))

# Run formatter on file in the git index. Creates a new git object with the
# result, and replaces the content of the file in the index with that object.
# Returns hash of the new object if formatting produced any changes.
def format_file_in_index(formatter, diff_entry, update_working_tree=True, write=True):
    orig_hash = diff_entry['dst_hash']
    new_hash = format_object(formatter, orig_hash, diff_entry['src_path'])

    # If the new hash is the same then the formatter did not make any changes.
    if not write or new_hash == orig_hash:
        return None

    # If the content of the new object is empty then the formatter did not
    # produce any output. We want to abort instead of replacing the file with an
    # empty one.
    if object_is_empty(new_hash):
        return None

    replace_file_in_index(diff_entry, new_hash)

    if update_working_tree:
        try:
            patch_working_file(diff_entry['src_path'], orig_hash, new_hash)
        except Exception as err:
            # Errors patching working tree files are not fatal
            warn(str(err))

    return new_hash

file_path_placeholder = re.compile('\{\}')

# Run formatter on a git blob identified by its hash. Writes output to a new git
# blob, and returns the hash of the new blob.
def format_object(formatter, object_hash, file_path):
    get_content = subprocess.Popen(
            ['git', 'cat-file', '-p', object_hash],
            stdout=subprocess.PIPE
            )
    format_content = subprocess.Popen(
            re.sub(file_path_placeholder, file_path, formatter),
            shell=True,
            stdin=get_content.stdout,
            stdout=subprocess.PIPE
            )
    write_object = subprocess.Popen(
            ['git', 'hash-object', '-w', '--stdin'],
            stdin=format_content.stdout,
            stdout=subprocess.PIPE
            )

    get_content.stdout.close()
    format_content.stdout.close()

    if get_content.wait() != 0:
        raise ValueError('unable to read file content from object database: ' + object_hash)

    if format_content.wait() != 0:
        raise Exception('formatter exited with non-zero status') # TODO: capture stderr from format command

    new_hash, err = write_object.communicate()

    if write_object.returncode != 0:
        raise Exception('unable to write formatted content to object database')

    return new_hash.decode('utf-8').rstrip()

def object_is_empty(object_hash):
    get_content = subprocess.Popen(
            ['git', 'cat-file', '-p', object_hash],
            stdout=subprocess.PIPE
        )
    content, err = get_content.communicate()

    if get_content.returncode != 0:
        raise Exception('unable to verify content of formatted object')

    return not content

def replace_file_in_index(diff_entry, new_object_hash):
    subprocess.check_call(['git', 'update-index',
        '--cacheinfo', '{},{},{}'.format(
            diff_entry['dst_mode'],
            new_object_hash,
            diff_entry['src_path']
            )])

def patch_working_file(path, orig_object_hash, new_object_hash):
    patch = subprocess.check_output(
            ['git', 'diff', orig_object_hash, new_object_hash]
            )

    # Substitute object hashes in patch header with path to working tree file
    patch_b = patch.replace(orig_object_hash.encode(), path.encode()).replace(new_object_hash.encode(), path.encode())

    apply_patch = subprocess.Popen(
            ['git', 'apply', '-'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
            )

    output, err = apply_patch.communicate(input=patch_b)

    if apply_patch.returncode != 0:
        raise Exception('could not apply formatting changes to working tree file {}'.format(path))

# Format: src_mode dst_mode src_hash dst_hash status/score? src_path dst_path?
diff_pat = re.compile('^:(\d+) (\d+) ([a-f0-9]+) ([a-f0-9]+) ([A-Z])(\d+)?\t([^\t]+)(?:\t([^\t]+))?$')

# Parse output from `git diff-index`
def parse_diff(diff):
    m = diff_pat.match(diff)
    if not m:
        raise ValueError('Failed to parse diff-index line: ' + diff)
    return {
            'src_mode': unless_zeroed(m.group(1)),
            'dst_mode': unless_zeroed(m.group(2)),
            'src_hash': unless_zeroed(m.group(3)),
            'dst_hash': unless_zeroed(m.group(4)),
            'status': m.group(5),
            'score': int(m.group(6)) if m.group(6) else None,
            'src_path': m.group(7),
            'dst_path': m.group(8)
            }

zeroed_pat = re.compile('^0+$')

# Returns the argument unless the argument is a string of zeroes, in which case
# returns `None`
def unless_zeroed(s):
    return s if not zeroed_pat.match(s) else None

def get_git_root():
    return subprocess.check_output(
            ['git', 'rev-parse', '--show-toplevel']
            ).decode('utf-8').rstrip()

def normalize_path(p, relative_to=None):
    return os.path.abspath(
            os.path.join(relative_to, p) if relative_to else p
            )

def matches_some_path(patterns, target):
    is_match = False
    for signed_pattern in patterns:
        (is_pattern_positive, pattern) = from_signed_pattern(signed_pattern)
        if fnmatch(target, normalize_path(pattern)):
            is_match = is_pattern_positive
    return is_match

# Checks for a '!' as the first character of a pattern, returns the rest of the
# pattern in a tuple. The tuple takes the form (is_pattern_positive, pattern).
# For example:
#     from_signed_pattern('!pat') == (False, 'pat')
#     from_signed_pattern('pat') == (True, 'pat')
def from_signed_pattern(pattern):
    if pattern[0] == '!':
        return (False, pattern[1:])
    else:
        return (True, pattern)

class CustomArgumentParser(argparse.ArgumentParser):
    def parse_args(self, args=None, namespace=None):
        args, argv = self.parse_known_args(args, namespace)
        if argv:
            msg = argparse._(
                    'unrecognized arguments: %s. Do you need to quote your formatter command?'
                    )
            self.error(msg % ' '.join(argv))
        return args

if __name__ == '__main__':
    parser = CustomArgumentParser(
            description='Transform staged files using a formatting command that accepts content via stdin and produces a result via stdout.',
            epilog='Example: %(prog)s --formatter "prettier --stdin-filepath \'{}\'" "src/*.js" "test/*.js"'
            )
    parser.add_argument(
            '--formatter', '-f',
            required=True,
            help='Shell command to format files, will run once per file. Occurrences of the placeholder `{}` will be replaced with a path to the file being formatted. (Example: "prettier --stdin-filepath \'{}\'")'
            )
    parser.add_argument(
            '--no-update-working-tree',
            action='store_true',
            help='By default formatting changes made to staged file content will also be applied to working tree files via a patch. This option disables that behavior, leaving working tree files untouched.'
            )
    parser.add_argument(
            '--no-write',
            action='store_true',
            help='Prevents %(prog)s from modifying staged or working tree files. You can use this option to check staged changes with a linter instead of formatting. With this option stdout from the formatter command is ignored. Example: %(prog)s --no-write -f "eslint --stdin --stdin-filename \'{}\' >&2" "*.js"'
            )
    parser.add_argument(
            '--version',
            action='version',
            version='%(prog)s version {}'.format(VERSION),
            help='Display version of %(prog)s'
            )
    parser.add_argument(
            'files',
            nargs='+',
            help='Patterns that specify files to format. The formatter will only transform staged files that are given here. Patterns may be literal file paths, or globs which will be tested against staged file paths using Python\'s fnmatch function. For example "src/*.js" will match all files with a .js extension in src/ and its subdirectories. Patterns may be negated to exclude files using a "!" character. Patterns are evaluated left-to-right. (Example: "main.js" "src/*.js" "test/*.js" "!test/todo/*")'
            )
    args = parser.parse_args()
    files = vars(args)['files']
    format_staged_files(
            file_patterns=files,
            formatter=vars(args)['formatter'],
            git_root=get_git_root(),
            update_working_tree=not vars(args)['no_update_working_tree'],
            write=not vars(args)['no_write']
            )
