class LoopArray < Array
  def []=(*args)
    args[0] = args[0] % size
    super(*args)
  end

  def [](*args)
    args[0] = args[0] % size
    super(*args)
  end
end

class Kreacher
  DEFAULTS = {
    cna:    LoopArray.new(10, 0),
    memory: LoopArray.new(32, 0),
    pc:     0,
    x:      0,
    y:      0
  }

  def initialize(opts={})
    DEFAULTS.merge(opts).each do |k ,v|
      instance_variable_set "@#{k}", v
    end
  end

  def pos
    [@x,@y]
  end

  def x
    @x
  end

  def y
    @y
  end

  def cna_nop()
    @pc = @pc+1 % @cna.size
  end

  def cna_let(mem_id, val)
    @memory[mem_id % @memory.size] = val
    @pc = @pc+3 % @cna.size
  end

  def cna_add(mem_id, val)
    @memory[mem_id] += val
    @pc = @pc+3 % @cna.size
  end

  def cna_sub(mem_id, val)
    @memory[mem_id] -= val
    @pc = @pc+3 % @cna.size
  end

  def cna_mul(mem_id, val)
    @memory[mem_id] *= val
    @pc = @pc+3 % @cna.size
  end

  def cna_mod(mem_id, val)
    @memory[mem_id] %= val
    @pc = @pc+3 % @cna.size
  end

  def cna_div(mem_id, val)
    @memory[mem_id] = (@memory[mem_id] / val).to_i
    @pc = @pc+3 % @cna.size
  end

  def cna_jmp(pos)
    @pc = pos % @cna.size
  end

  def cna_jis(mem_id, val, pos)
    @pc = @memory[mem_id] < val ? pos : @pc+4 % @cna.size
  end

  def cna_jig(mem_id, val, pos)
    @pc = @memory[mem_id] > val ? pos : @pc+4 % @cna.size
  end

  def cna_jie(mem_id, val, pos)
    @pc = @memory[mem_id] == val ? pos : @pc+4 % @cna.size
  end

  def cna_jiu(mem_id, val, pos)
    @pc = @memory[mem_id] != val ? pos : @pc+4 % @cna.size
  end

  def cna_wlk(dir)
    case dir % 4
    when 0 then @y -= 1
    when 1 then @x += 1
    when 2 then @y += 1
    when 3 then @x -= 1
    end
    @pc = @pc+2 % @cna.size
  end

  COMMANDS = instance_methods.grep(/^cna_.*/)

  def step
    cmd    = method(COMMANDS[@cna[@pc] % COMMANDS.size])
    params = cmd.arity.times.map{|i| @cna[(@pc + 1 + i) % @cna.size]}
    cmd.call *params
  end

  def to_s
    s = [COMMANDS[@cna[@pc] % COMMANDS.size], @cna[@pc+1..@pc+4]]
    "Current Instruction: #{s.inspect}\n" +
    "PC = #@pc\n" +
    "X  = #@x\n" +
    "Y  = #@y\n" +
    @memory.inspect
  end
end


# INITIALIZATION
width      = 64
height     = 36
population = 10
cna_size   = 256
kreachers = population.times.map do |i|
  r = Random.new(i)
  r = LoopArray.new(cna_size.times.map{ |i| r.rand([cna_size,Kreacher::COMMANDS.size].max) })
  Kreacher.new(cna: r, x: rand(width), y: rand(height))
end

# SIMULATION
i=0
loop do
  s="step #{i+=1}\n"
  positions = kreachers.reduce(Hash.new(0)){|s,e| s[[e.x%width,e.y%height]]+=1; s}
  height.times do |y|
    width.times do |x|
      s << case positions[[x,y]]
           when 0 then '.'
           when 1 then 'x'
           else '#'
           end
    end
    s << "\n"
  end
  puts "#{s}\n"
  kreachers.each{|k| k.step}
end

