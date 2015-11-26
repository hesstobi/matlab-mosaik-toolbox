# Mosaik Toolbox

## Quickstart

It is recommended for Mosaik toolbox to run MATLab 2015b or later. Earlier versions have not been tested.

For socket communication you need [JSONLab](http://www.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files-in-matlab-octave) or provided in our repository (**jsonlab-1.x.mltbx**). Just install the toolbox or put the .m files in your MATLab path.

Then you can just install the Mosaik toolbox (**mosaiktlbx-x.x.mltbx**).

## Scenario Definition

For detailed scenario definition please refer to the official [mosaik documentation](http://mosaik.readthedocs.org/en/latest/scenario-definition.html) first.

To initiate a simulator, add the following to your `sim_config`:
```python
sim_config = {
    'Matlab': {
		'cwd': os.path.dirname(os.path.realpath(__file__)),
		'cmd': 'matlab.exe -minimize -nosplash -r "server=\'%(addr)s\';Simulator(\'%(addr)s\')"'
	}
}
```
Where *Simulator* is the name of your simulator and has to be in the same folder as your **demo.py**. If you need to use a simulator which is not in the same folder, use the following syntax:
```python
sim_config = {
    'Matlab': {
		'cwd': os.path.dirname(os.path.realpath(__file__)),
		'cmd': 'matlab.exe -minimize -nosplash -r "Package.Simulator(\'%(addr)s\')"'
	}
}
```
Where *Package* is your MATLab package containing the *Simulator*. In this example, the folder structure would be `\+Package\Simulator.m`.

It is also recommended to increase the timeout since MATLab can take a little time to load. This can be done by changing the `mosaik_config`:
```python
mosaik_config = {
    'start_timeout': 600,  # seconds
    'stop_timeout': 10,  # seconds
}
```
Then, start the world using your just created `sim_config` and `mosaik_config`:
```
world = mosaik.World(sim_config, mosaik_config)
```
You can now start your simulators and instantiate models as described in the official documentation:
```python
matlab = world.start('Matlab', step_size=10)
model = matlab.Model(parameter=x)
```

There are is a Mosaik toolbox specific utilities which is very practical but its scenario definition is not explained in the official documentation. Please note that you have to read the official part explaining scenario definition first, before using those utilites:

### Collector

The collector utility is used to create tables or graphical plots from the simulation data.

First, change the `sim_config`:
```python
sim_config = {
    'Matlab': {
		'cwd': os.path.dirname(os.path.realpath(__file__)),
		'cmd': 'matlab.exe -minimize -nosplash -r "MosaikUtilites.Collector(\'%(addr)s\')"'
	}
}
```
Start the simulator defining the accuray via its **step_size**:
```python
monitor = world.start('Monitor', step_size=10)
```
The collectors only model is **Collector**:
```python
collector = monitor.Collector(graphical_output=True)
```
Set `graphical_output=True` if you wish to obtain a graphical plot of the simulated data. You can also set `save_path=filename.m` if you wish to save your data.

To incorporate an attribute from another model into the collector just it to collector:
```python
world.connect(model, collector, 'attribute')
```

The collector plots all attributes with the same name in one figure.

## Developer's Guide

### API Reference

#### MosaikAPI

**class MosaikAPI.Simulator**

This is the base that you need to inherit from when developing simulators.

`meta()`

**Description:**
Creates meta information struct.  

**Return:**  
**_Name:_**  
value
**_Type:_**  
*Struct*  
**_Description:_**  
Meta information in the form `attribute = value`.  
Required attributes: *api_version*, *extra_methods*, *models*

`create(num,model,varargin)`

**Description:**  
Creates models of specified amount, type and initial parameters. Returns information about created models.

**Parameters:**  
**_Name:_**  
num  
**_Type:_**  
*Double*  
**_Description:_**  
Amount of models to be created.  
**_Name:_**  
model  
**_Type:_**  
*String*  
**_Description:_**  
Type of model to be created.  
**_Name:_**  
model_params  
**_Type:_**  
*Keyword arguments*  
**_Description:_**  
Model creation parameters.

**Return:**  
**_Name:_**  
entity_list  
**_Type:_**  
*Cell*  
**_Description:_**
Contains information structs about created models in the form `attribute = value`.  
Required attributes: *eid*, *type*  
Optional attributes: *rel*, *children*

`step(time,varargin)`

**Description:**  
Creates models of specified amount, type and initial parameters. Returns information about created models.

**Parameters:**  
**_Name:_**  
time  
**_Type:_**  
*Double*  
**_Description:_**  
Simulation time of last step.  
**_Name:_**  
inputs  
**_Type:_**  
*Keyword arguments*  
**_Description:_**  
Input values in the form `destination_full_id.attributes.source_full_id = value`.

**Return:**  
**_Name:_**  
time_next_step  
**_Type:_**  
*Cell*  
**_Description:_**
Contains information structs about created models in the form `attribute = value`.  
Required attributes: *eid*, *type*  
Optional attributes: *rel*, *children*

`get_data(outputs)`

**Description:**  
Creates models of specified amount, type and initial parameters. Returns information about created models.

**Parameters:**  
**_Name:_**  
num  
**_Type:_**  
*Double*  
**_Description:_**  
Amount of models to be created.  
**_Name:_**  
model  
**_Type:_**  
*String*  
**_Description:_**  
Type of model to be created.  
**_Name:_**  
varargin  
**_Type:_**  
*Keyword arguments*  
**_Description:_**  
Various arguments regarding model creation.

**Return:**  
**_Name:_**  
entity_list  
**_Type:_**  
*Cell*  
**_Description:_**
Contains information structs about created models in the form `attribute = value`.  
Required attributes: *eid*, *type*  
Optional attributes: *rel*, *children*

#### MosaikUtilites

**class MosaikAPI.Model**

This is the base that you need to inherit from when just defining models. The simulator used in this case is `MosaikAPI.ModelSimulator`.

`meta()`

**Description:**  
Creates models of specified amount, type and initial parameters. Returns information about created models.

**Parameters:**  
**_Name:_**  
num  
**_Type:_**  
*Double*  
**_Description:_**  
Amount of models to be created.  
**_Name:_**  
model  
**_Type:_**  
*String*  
**_Description:_**  
Type of model to be created.  
**_Name:_**  
varargin  
**_Type:_**  
*Keyword arguments*  
**_Description:_**  
Various arguments regarding model creation.

**Return:**  
**_Name:_**  
entity_list  
**_Type:_**  
*Cell*  
**_Description:_**
Contains information structs about created models in the form `attribute = value`.  
Required attributes: *eid*, *type*  
Optional attributes: *rel*, *children*

`step(varargin)`

**Description:**  
Creates models of specified amount, type and initial parameters. Returns information about created models.

**Parameters:**  
**_Name:_**  
num  
**_Type:_**  
*Double*  
**_Description:_**  
Amount of models to be created.  
**_Name:_**  
model  
**_Type:_**  
*String*  
**_Description:_**  
Type of model to be created.  
**_Name:_**  
varargin  
**_Type:_**  
*Keyword arguments*  
**_Description:_**  
Various arguments regarding model creation.

**Return:**  
**_Name:_**  
entity_list  
**_Type:_**  
*Cell*  
**_Description:_**
Contains information structs about created models in the form `attribute = value`.  
Required attributes: *eid*, *type*  
Optional attributes: *rel*, *children*

**class MosaikAPI.Controller**

This is the base that you need to inherit from when developing controllers.

`makeSchedule(inputs)`

**Description:**  
Creates output values for controlled models based on input values and controller function.

**Parameters:**  
**_Name:_**  
inputs
**_Type:_**  
*Struct*  
**_Description:_**  
Input values in the form `destination_full_id.attributes.source_full_id = value`.

**Return:**  
**_Name:_**  
schedule  
**_Type:_**  
*Struct*  
**_Description:_**  
Output values in the form `source_full_id._destination_full_id.attribute = value`.


### Example Demos

To understand the basic functionality there are example demos provided. It is also recommended to use the examples as reference when reading the developer's guide.

#### ExampleSim

#### ExampleMas

#### ExampleBatteryLoadSim

#### ExampleBatteryLoadSimControlled
