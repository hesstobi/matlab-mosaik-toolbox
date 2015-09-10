# Setup
import mosaik

sim_config = {
    'Battery': {
    	'cwd': 'C:\\Users\\sjras\\OneDrive\\Dokumente\\MATLAB\\IEEHMosaikToolbox\\Example\\Battery-Load-Simulation',
        'cmd': 'matlab.exe -r "server=\'%(addr)s\';Battery(server)"'
    },
    'Load': {
    	'cwd': 'C:\\Users\\sjras\\OneDrive\\Dokumente\\MATLAB\\IEEHMosaikToolbox\\Example\\Battery-Load-Simulation',
        'cmd': 'matlab.exe -r "server=\'%(addr)s\';Load(server)"'
    },
    'Display': {
        'cwd': 'C:\\Users\\sjras\\OneDrive\\Dokumente\\MATLAB\\IEEHMosaikToolbox\\Example\\Battery-Load-Simulation',
        'cmd': 'matlab.exe -r "server=\'%(addr)s\';Display(server)"'
    }
}

mosaik_config = {
    'start_timeout': 300,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

# Start simulators
exsim_0 = world.start('Battery', step_size=10)
exsim_1 = world.start('Load', step_size=10)
exsim_2 = world.start('Display', step_size=10)

# Instantiate models
battery_set = [exsim_0.Battery(init_capacitance=(i+1)*5*3600, init_voltage=10) for i in range(3)] # 5 Ah at 10V
load_set = [exsim_1.Load(resistance=(i+1)*2, voltage=10, tolerance=0.2) for i in range(3)]
display = exsim_2.Graph()

# Connect entities
for a, b in zip(battery_set, load_set):
    world.connect(a, b, ('voltage_out', 'voltage_in'), async_requests=True)

mosaik.util.connect_many_to_one(world, battery_set, display, ('data_out', 'data_in'), async_requests=True)
mosaik.util.connect_many_to_one(world, load_set, display, ('data_out', 'data_in'), async_requests=True)
# Run simulation
END = 3600
world.run(until=END)