local COM_PRES={0x34,0x74,0xB4,0xF4}
local id=0

local function twoCompl(v)if v>32767 then v=-(65535-v+1) end return v end

local function read_reg(a,l)
  i2c.start(id)
  i2c.address(id,0x77,i2c.TRANSMITTER)
  i2c.write(id,a)
  i2c.stop(id)
  i2c.start(id)
  i2c.address(id,0x77,i2c.RECEIVER)
  c = i2c.read(id,l)
  i2c.stop(id)
  return c
end

local function write_reg(a,v)
  i2c.start(id)
  i2c.address(id,0x77,i2c.TRANSMITTER)
  i2c.write(id,a)
  i2c.write(id,v)
  i2c.stop(id)
end

local function byte(a,v) return string.byte(a,v)end

function init(t)
  _BMP180={}
  if not _I2C then i2c.setup(id,t.sda,t.scl,i2c.SLOW)end
  local c = read_reg(0xAA, 22)
  _BMP180.AC1 = twoCompl(byte(c,1)*256+byte(c,2))
  _BMP180.AC2 = twoCompl(byte(c,3)*256+byte(c,4))
  _BMP180.AC3 = twoCompl(byte(c,5)*256+byte(c,6))
  _BMP180.AC4 = byte(c,7)*256+byte(c,8)
  _BMP180.AC5 = byte(c,9)*256+byte(c,10)
  _BMP180.AC6 = byte(c,11)*256+byte(c,12)
  _BMP180.B1 = twoCompl(byte(c,13)*256+byte(c,14))
  _BMP180.B2 = twoCompl(byte(c,15)*256+byte(c,16))
  _BMP180.MB = twoCompl(byte(c,17)*256+byte(c,18))
  _BMP180.MC = twoCompl(byte(c,19)*256+byte(c,20))
  _BMP180.MD = twoCompl(byte(c,21)*256+byte(c,22))
end

local function read_temp()
  write_reg(0xF4,0x2E)
  tmr.delay(5000)
  local d = read_reg(0xF6, 2)
  UT=byte(d,1)*256+byte(d, 2)
  local X1 = (UT - _BMP180.AC6) * _BMP180.AC5 / 32768
  local X2 = _BMP180.MC * 2048 / (X1 + _BMP180.MD)
  B5 = X1 + X2
  t = (B5 + 8) / 16
  return((t/10).."."..(t%10))
end

local function read_pressure(oss)
  write_reg(0xF4, COM_PRES[oss + 1]);
  tmr.delay(30000);
  local d=read_reg(0xF6,3)
  local UP=byte(d,1)*65536+byte(d,2)*256+byte(d,1)
  UP=UP/2^(8-oss)
  local B6=B5-4000
  local X1=_BMP180.B2*(B6*B6/4096)/2048
  local X2=_BMP180.AC2*B6/2048
  local X3=X1+X2
  local B3 = ((_BMP180.AC1 * 4 + X3) * 2 ^ oss + 2) / 4
  X1=_BMP180.AC3*B6/8192
  X2=(_BMP180.B1*(B6*B6/4096))/65536
  X3=(X1+X2+2)/4
  local B4=_BMP180.AC4*(X3+32768)/32768
  local B7=(UP-B3)*(50000/2^oss)
  p=(B7/B4)*2
  X1=(p/256)*(p/256)
  X1=(X1*3038)/65536
  X2=(-7357*p)/65536
  p=p+(X1+X2+3791)/16
  return (p*75/10000).."."..((p*75 % 10000)/1000)
end

return function (d)
local r=false
if d.init then r=init(d.init)end
if _BMP180 then
 if d.temp then r=read_temp()end
 if d.pres then r=read_pressure(d.pres)end
end
return r
end
