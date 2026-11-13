"""Compare Lua 5.1 executable instructions, ignoring debug names/line numbers.

Usage: python tools/verify_refactor.py PATH_TO_ORIGINAL_LUA_FILES
Requires lupa. Generated database files must remain byte-for-byte identical.
"""
import sys
from pathlib import Path

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
GENERATED = {'LootReference.lua', 'PortraitDisplays.lua', 'Metadata.lua'}


class LuaChunk:
    def __init__(self, data):
        assert data[:6] == b'\x1bLua\x51\0', 'Expected Lua 5.1 bytecode'
        self.data = data
        self.position = 12
        self.order = 'little' if data[6] else 'big'
        self.int_size, self.size_t, self.instruction_size, self.number_size = data[7:11]

    def read(self, size):
        result = self.data[self.position:self.position + size]
        assert len(result) == size
        self.position += size
        return result

    def integer(self, size=None):
        return int.from_bytes(self.read(size or self.int_size), self.order)

    def string(self):
        return self.read(self.integer(self.size_t))

    def function(self):
        self.string()  # Source filename (debug only).
        self.read(self.int_size * 2)  # First/last source lines.
        signature = self.read(4)  # Upvalues, parameters, vararg flags, stack size.
        instructions = self.read(self.integer() * self.instruction_size)
        constants = []
        for _ in range(self.integer()):
            kind = self.integer(1)
            if kind == 0:
                value = None
            elif kind == 1:
                value = self.read(1)
            elif kind == 3:
                value = self.read(self.number_size)
            elif kind == 4:
                value = self.string()
            else:
                raise AssertionError(f'Unknown constant type: {kind}')
            constants.append((kind, value))
        children = [self.function() for _ in range(self.integer())]
        self.read(self.integer() * self.int_size)  # Debug line-number table.
        for _ in range(self.integer()):
            self.string()
            self.read(self.int_size * 2)  # Debug local lifetime.
        for _ in range(self.integer()):
            self.string()  # Debug upvalue name.
        return signature, instructions, constants, children


def verify(original_directory):
    runtime = LuaRuntime(encoding=None)
    compile_chunk = runtime.eval(b'function(source) return string.dump(assert(loadstring(source))) end')
    count = 0
    for current in sorted((ROOT / 'RaynnaTracker').glob('*.lua')):
        original = original_directory / current.name
        before, after = original.read_bytes(), current.read_bytes()
        if current.name in GENERATED:
            assert before == after, f'Generated data changed: {current.name}'
        else:
            old_chunk, new_chunk = LuaChunk(compile_chunk(before)), LuaChunk(compile_chunk(after))
            assert old_chunk.function() == new_chunk.function(), f'Executable behavior changed: {current.name}'
            assert old_chunk.position == len(old_chunk.data)
            assert new_chunk.position == len(new_chunk.data)
        print(f'PASS: {current.name} unchanged executable instructions/data')
        count += 1
    print(f'Verified {count} Lua files; only source/debug presentation may differ.')


if __name__ == '__main__':
    verify(Path(sys.argv[1]))
