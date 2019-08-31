require 'rpi_gpio'

class FS
  TEMP_THRESHOLD_LOW = 50
  TEMP_THRESHOLD_HIGH = 70
  FAN_OFFSET = 25

  def initialize
    RPi::GPIO.set_warnings false
    RPi::GPIO.set_numbering :bcm
    RPi::GPIO.setup 2, :as => :output

    @pwm = RPi::GPIO::PWM.new(2, 100)
    @last_temp = 0
    @current_temp = 0

    @pwm.start 0

    puts "FanSpeed is running."
  end

  def get_cpu_temp
    File.open('/sys/class/thermal/thermal_zone0/temp', 'r') do |file|
      file.readline.to_i / 1000.0
    end
  end

  def update
    current_temp = get_cpu_temp

    @pwm.duty_cycle = [[(current_temp - TEMP_THRESHOLD_LOW) / (TEMP_THRESHOLD_HIGH - TEMP_THRESHOLD_LOW) * 100 + FAN_OFFSET, 100].min, 0].max

    if current_temp > TEMP_THRESHOLD_LOW
      if @last_temp <= TEMP_THRESHOLD_LOW
        puts "Fan is waked up."
      end
      puts "[#{current_temp.round(2)}] Fan speed is around #{@pwm.duty_cycle.to_i}%."
    else
      puts "Fan is sleeping."
    end

    @last_temp = current_temp
  end

  def clean_up
    @pwm.stop
    RPi::GPIO.clean_up 2

    puts "FanSpeed stops."
  end
end

fs = FS.new

Signal.trap("INT") do
  puts "Interrupted."
  
  fs.clean_up

  exit
end


loop do
  fs.update

  sleep 5
end
