local HCC = require "HC"
local Class = require "hump.class"
local Vector = require "hump.vector-light"
local math = require "math"
local Timer = require "hump.timer"


Mov = Class{
    init = function(self, hero, shape)
        self.shape = shape
        self.hero = hero
        self.v = 100
        self.moved = 0
        --self.img = love.graphics.newImage("img/sonar.png")
    end;
}

function Mov:draw()
  self.shape:draw('fill')
end


function Mov:update(dt)
  local delta = self.v * dt
  self.shape:move(delta, 0)
  if self.shape:collidesWith(self.hero) then
    self.hero:move(delta, 0)
  end
  self.moved = self.moved + delta
  if self.moved < 0 and delta < 0 then self.v = 0 - self.v end
  if self.moved > 650 and delta > 0 then self.v = 0 - self.v end
end
