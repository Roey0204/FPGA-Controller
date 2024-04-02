# FPGA-Controller

## Title: Design of Zigbee based wireless stepper motor controller using FPGA
- Design stepper motor FPGA controller using Quartus II software.
- PWM technique and A4988 drivers were designed in FPGA controller to rotate the
motor with adjustable angles, speeds and direction.
o Desired angle can be performed by calculating the step angle of the stepper motor.
o PWM technique apply on speed of stepper motor by controlling the width of the
pulse
- Zero position detection of the system also designed by placing the magnetic sensor
at the 0 position.
- Wireless communication using XBee were establish through FPGA controller to send
and receive data from host to the slave devices.
o UART was used by taking bytes of data and transmitting individual bits in a sequential
fashion.
- Graphic user Interface (GUI) was created using Visual Studio(C#) to perform the
wireless connection between FPGA board and PC.
- Result such as square wave or number of clock can be simulated using ModelSim in
Quartus II.

## Idea Concept - Blog diagram
<img src="https://github.com/Roey0204/FPGA-Controller/blob/main/img/Block%20diagram.png" alt="Image1" width=700 height=500>

## Schematic Diagram
<img src="https://github.com/Roey0204/FPGA-Controller/blob/main/img/Schematic.PNG" alt="Image1" width=700 height=500>

## FPGA UART Controller Architecture
<img src="https://github.com/Roey0204/FPGA-Controller/blob/main/img/Architecture.png" alt="Image1" width=850 height=500>

## Result 
<img src="https://github.com/Roey0204/FPGA-Controller/blob/main/img/result.png" alt="Image1">
