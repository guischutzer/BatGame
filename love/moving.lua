local HCC = require "HC"
local Class = require "hump.class"
local Vector = require "hump.vector-light"
local math = require "math"
local Timer = require "hump.timer"


Mov = Class{
    init = function(self, hero, shape, right)
        self.shape = shape
        self.hero = hero
        self.v = -200
        if (right) then self.v = 200 end
        self.amplitude = 590
        self.moved = 0
        if (not right) then self.moved = self.amplitude end
        self.img = love.graphics.newImage("img/plat.png")
        --self.img = love.graphics.newImage("img/sonar.png")
    end;
}

function Mov:draw()
  --self.shape:draw('fill')
  local cx, cy = self.shape:bbox()
  local hx, hy = self.hero:center()
  if (hx - cx > 500 or hx - cx < -500) then return end
  if (hy - cy > 400 or hy - cy < -400) then return end
  love.graphics.draw(self.img, cx, cy)
end


function Mov:update(dt)
  local delta = self.v * dt
  self.shape:move(delta, 0)
  if self.shape:collidesWith(self.hero) then
    self.hero:move(delta, 0)
  end
  self.moved = self.moved + delta
  if self.moved < 0 and delta < 0 then self.v = 0 - self.v end
  if self.moved > self.amplitude and delta > 0 then self.v = 0 - self.v end
end
