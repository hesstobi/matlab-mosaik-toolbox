import mosaik
import os.path

sim_config = {
	'Matlab': {
		'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
		'cmd': 'matlab.exe -r "server=\'%(addr)s\';ExampleSim(\'%(addr)s\')"'
	},
	'Monitor': {
		'cwd': os.path.dirname(os.path.realpath(__file__)), # Set here the path of your Matlab Simulator
		'cmd': 'matlab.exe -r "MosaikUtilities.Collector(\'%(addr)s\')"'
	}
}

mosaik_config = {
	'start_timeout': 600,  # seconds
	'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

matlab  = world.start('Matlab', step_size=1)
monitor  = world.start('Monitor', step_size=1)

model = matlab.Model(init_value=2)
model2 = matlab.Model(init_value=5)
collector = monitor.Collector(graphical_output=True)

world.connect(model, collector, 'val', 'delta')
world.connect(model2, collector, 'val', 'delta')


world.run(until=10)

#exsim_0.wtimes('Hallo', times=23)

world.shutdown()
