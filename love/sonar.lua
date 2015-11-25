local HCC = require "HC"
local Class = require "hump.class"
local Vector = require "hump.vector-light"
local math = require "math"
local Timer = require "hump.timer"


Sonar = Class{
    init = function(self, hero, shape)
        self.shape = shape
        self.ativo = false
        self.retorno = false
        self.hero = hero
        self.v = 900
        self.t = 0
        self.lifespan = 0.75
        self.img = love.graphics.newImage("img/sonar.png")
    end;
}

function Sonar:draw()
  if self.ativo then
    local xc, yc = self.shape:bbox()
    local r = math.atan2(self.dy, self.dx) + 2*  math.pi / 4
    love.graphics.draw(self.img, xc, yc, r)
  end
end

function Sonar:resetar()
  print(self.t)
  self.ativo = false
  self.retorno = false
  self.shape:moveTo(1,1)
end

function Sonar:update(dt)
    if (self.ativo) then
      if self.retorno then
        self:retornar(dt)
      else
        self:avancar(dt)
      end
    end
end

function Sonar:colidiu()
  self.retorno = true
end

function Sonar:retornar(dt)
  local sx, sy = self.shape:center()
  local hx, hy = self.hero:center()
  self.dx, self.dy = Vector.normalize(hx - sx, hy - sy)
  self.shape:move(self.dx * self.v * dt, self.dy * self.v * dt)
  if self.shape:collidesWith(self.hero) then
    self:resetar()
  end
end

function Sonar:avancar(dt)
  self.t = self.t + dt
  local sx, sy = self.shape:center()
  local hx, hy = self.hero:center()
  if self.t > self.lifespan then
    --print("OPOPO")
    self:resetar()
  end
  self.shape:move(self.dx * self.v * dt, self.dy * self.v * dt)
  --print(self.shape:center())
end


function Sonar:ativar(xa, ya, xb, yb)
    self.t = 0
    self.ativo = true
    local dx, dy = Vector.normalize(xb - xa, yb - ya)
    self.dx, self.dy = dx, dy
    self.shape:moveTo(xa + 40 * dx, ya + 40 * dy)
end
