##
##

from typing import Union, List
import subprocess
import logging
import io
from io import BytesIO

logger = logging.getLogger('hostprep.shell')
logger.addHandler(logging.NullHandler())


class ShellCommandError(Exception):
    pass


class RCNotZero(Exception):
    pass


class RunShellCommand(object):

    def __init__(self):
        pass

    @staticmethod
    def cmd_exec(command: Union[str, List[str]], directory: str):
        buffer = io.BytesIO()
        logger.debug(f"Shell command: {' '.join(command)}")

        p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, cwd=directory)

        while True:
            data = p.stdout.read()
            if not data:
                break
            buffer.write(data)

        p.communicate()

        if p.returncode != 0:
            raise ShellCommandError("command exited with non-zero return code")

        buffer.seek(0)
        return buffer

    @staticmethod
    def cmd_output(command: Union[str, List[str]], directory: str, split: bool = False, split_sep: str = None):
        out_lines = []
        output = BytesIO()
        try:
            output: BytesIO = RunShellCommand().cmd_exec(command, directory)
        except ShellCommandError:
            out_text = output.read().decode("utf-8")
            raise RCNotZero(out_text)

        while True:
            line = output.readline()
            if not line:
                break
            line_string = line.decode("utf-8").strip()
            if len(line_string) > 0:
                if split:
                    items = line_string.split(split_sep)
                    out_lines.append(items)
                else:
                    out_lines.append(line_string)

        return out_lines
