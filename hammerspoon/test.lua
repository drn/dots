-- Hammerspoon unit tests
-- Run: luajit hammerspoon/test.lua

package.path = './hammerspoon/?.lua;' .. package.path

local lib = require 'lib'

-- Test runner

local passed = 0
local failed = 0

local function eq(name, got, expected)
  if got == expected then
    passed = passed + 1
  else
    failed = failed + 1
    io.write('FAIL: '..name..'\n  expected: '..tostring(expected)..'\n       got: '..tostring(got)..'\n')
  end
end

local function approx(name, got, expected, epsilon)
  epsilon = epsilon or 0.001
  if math.abs(got - expected) < epsilon then
    passed = passed + 1
  else
    failed = failed + 1
    io.write('FAIL: '..name..'\n  expected: '..tostring(expected)..'\n       got: '..tostring(got)..'\n')
  end
end

-- formatSeconds

eq('0 seconds',         lib.formatSeconds(0),     '0s')
eq('1 second',          lib.formatSeconds(1),     '1s')
eq('30 seconds',        lib.formatSeconds(30),    '30s')
eq('59 seconds',        lib.formatSeconds(59),    '59s')
eq('60 seconds = 1m',   lib.formatSeconds(60),    '1m 0s')
eq('61 seconds',        lib.formatSeconds(61),    '1m 1s')
eq('90 seconds',        lib.formatSeconds(90),    '1m 30s')
eq('5 minutes',         lib.formatSeconds(300),   '5m 0s')
eq('59m 59s',           lib.formatSeconds(3599),  '59m 59s')
eq('1 hour',            lib.formatSeconds(3600),  '1h 0m 0s')
eq('1h 1m 1s',          lib.formatSeconds(3661),  '1h 1m 1s')
eq('2h 30m 45s',        lib.formatSeconds(9045),  '2h 30m 45s')
eq('fractional floors', lib.formatSeconds(90.7),  '1m 30s')

-- frameForUnit

local screen = { x=0, y=0, w=1920, h=1080 }

local f = lib.frameForUnit(screen, { x=0, y=0, w=1, h=1 })
eq('full x', f.x, 0)
eq('full y', f.y, 0)
eq('full w', f.w, 1920)
eq('full h', f.h, 1080)

f = lib.frameForUnit(screen, { x=0.5, y=0, w=0.5, h=1 })
eq('right half x', f.x, 960)
eq('right half y', f.y, 0)
eq('right half w', f.w, 960)
eq('right half h', f.h, 1080)

f = lib.frameForUnit(screen, { x=0, y=0.5, w=0.5, h=0.5 })
eq('bottom-left x', f.x, 0)
eq('bottom-left y', f.y, 540)
eq('bottom-left w', f.w, 960)
eq('bottom-left h', f.h, 540)

-- frameForUnit with offset screen (external display)
local ext = { x=1920, y=0, w=2560, h=1440 }

f = lib.frameForUnit(ext, { x=0, y=0, w=0.5, h=0.5 })
eq('ext topleft x', f.x, 1920)
eq('ext topleft y', f.y, 0)
eq('ext topleft w', f.w, 1280)
eq('ext topleft h', f.h, 720)

f = lib.frameForUnit(ext, { x=0.5, y=0.5, w=0.5, h=0.5 })
eq('ext bottomright x', f.x, 1920 + 1280)
eq('ext bottomright y', f.y, 720)
eq('ext bottomright w', f.w, 1280)
eq('ext bottomright h', f.h, 720)

-- fitHorizontal unit
f = lib.frameForUnit(screen, { x=0.22, y=0, w=0.56, h=1 })
approx('fitH x', f.x, 422.4)
approx('fitH w', f.w, 1075.2)
eq('fitH y', f.y, 0)
eq('fitH h', f.h, 1080)

-- Results

io.write('\n'..passed..' passed, '..failed..' failed\n')
os.exit(failed > 0 and 1 or 0)
