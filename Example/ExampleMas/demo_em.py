import mosaik
import os.path

examplepath = os.path.split((os.path.dirname(os.path.realpath(__file__))))[0]

sim_config = {
    'MatlabMas': {
        'cwd': examplepath + '\ExampleMas',  # Set here the path of your Matlab Simulator
        'cmd': 'matlab.exe -minimize -nosplash -r "ExampleMas(\'%(addr)s\')"'
    },
    'MatlabSim': {
        'cwd': examplepath + '\ExampleSim',  # Set here the path of your Matlab Simulator
        'cmd': 'matlab.exe -minimize -nosplash -r "ExampleSim(\'%(addr)s\')"'
    },
    'Monitor': {
        'cwd': os.path.dirname(os.path.realpath(__file__)),  # Set here the path of your Matlab Simulator
        'cmd': 'matlab.exe -minimize -nosplash -r "MosaikUtilities.Collector(\'%(addr)s\')"'
    }
}

mosaik_config = {
    'start_timeout': 600,  # seconds
    'stop_timeout': 10,  # seconds
}

world = mosaik.World(sim_config, mosaik_config)

matlab1 = world.start('MatlabSim', step_size=10)
matlab2 = world.start('MatlabMas', step_size=10)
monitor = world.start('Monitor', step_size=10)

collector = monitor.Collector(graphical_output=True)

# Connect three models to three agents.

model_set = matlab1.Model.create(3)
agent_set = [matlab2.Agent(val=(i+1)*20) for i in range(3)]

for model, agent in zip(model_set, agent_set):
    world.connect(model, agent, ('val', 'link',), async_requests=True)

mosaik.util.connect_many_to_one(world, model_set, collector, 'val')


# Connect one model to an agent.
'''
model = matlab1.Model()
agent = matlab2.Agent()

world.connect(model,agent,('val','link',),async_requests=True)

world.connect(model,collector,'val')
'''

# Connect three models to an agent.
'''
model_set = matlab1.Model.create(3)
agent = matlab2.Agent()

mosaik.util.connect_many_to_one(world, model_set, agent, ('val','link',), async_requests=True)

mosaik.util.connect_many_to_one(world, model_set, collector, 'val')
'''

# Run simulation
world.run(until=300)
