# Setup
import mosaik
import os.path

sim_config = {
    'Matlab': {
		'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
		'cmd': 'matlab.exe -minimize -nosplash -r "ExampleBatteryLoadSim(\'%(addr)s\')"'
	},
	'Controller': {
		'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
		'cmd': 'matlab.exe -minimize -nosplash -r "Controller(\'%(addr)s\')"'
	},
	'Monitor': {
		'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
		'cmd': 'matlab.exe -minimize -nosplash -r "MosaikUtilities.Collector(\'%(addr)s\')"'
	}
}

mosaik_config = {
    'start_timeout': 600,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

# Start simulators
matlab1 = world.start('Matlab', step_size=10)
matlab2 = world.start('Matlab', step_size=10)
controller= world.start('Controller', step_size=10)
monitor = world.start('Monitor', step_size=10)

# Instantiate models
battery = matlab1.Battery(init_capacitance=5*3600) # 5 Ah at 10V
load = matlab2.Load(resistance=2)
controller = controller.Controller(init_voltage=10,shutdown_voltage=8)
collector = monitor.Collector(graphical_output=True)

# Connect entities
world.connect(battery, load, async_requests=True)
world.connect(battery, controller, 'capacitance', async_requests=True)
world.connect(load, controller, async_requests=True)

# Connect monitor
world.connect(battery, collector, 'voltage', 'capacitance')
world.connect(load, collector, 'total_consumed_cap')

# Run simulation
END = 300
world.run(until=END)