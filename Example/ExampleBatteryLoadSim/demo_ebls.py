# Setup
import mosaik
import os.path

sim_config = {
    'Matlab': {
		'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
		'cmd': 'matlab.exe -minimize -nosplash -r "ExampleBatteryLoadSim(\'%(addr)s\')"'
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
monitor = world.start('Monitor', step_size=10)

# Instantiate models
battery_set = [matlab1.Battery(init_capacitance=(i+1)*5*3600, init_voltage=10) for i in range(3)]  # 5 Ah at 10V
load_set = [matlab2.Load(resistance=(i+1)*2, voltage=10, tolerance=0.2) for i in range(3)]
collector = monitor.Collector(graphical_output=True)

# Connect entities
for a, b in zip(battery_set, load_set):
    world.connect(a, b, ('voltage', 'voltage_in'), async_requests=True)

# Connect monitor
mosaik.util.connect_many_to_one(world, load_set, collector, 'consumed_capacitance')
mosaik.util.connect_many_to_one(world, battery_set, collector, 'voltage', 'capacitance')

# Run simulation
END = 300
world.run(until=END)