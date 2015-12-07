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
		'cmd': 'matlab.exe -minimize -nosplash -r "Simulator(\'%(addr)s\')"'
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

To start your simulator in verbose mode (socket messages are displayed and simulator does not exit at the end) add `,\'verbose\',true` to your simulator parameters:
```python
sim_config = {
    'Matlab': {
		'cwd': os.path.dirname(os.path.realpath(__file__)),
		'cmd': 'matlab.exe -minimize -nosplash -r "Simulator(\'%(addr)s\',\'verbose\',true)"'
	}
}
```
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

##### class MosaikAPI.Simulator

This is the base that you need to inherit from when developing simulators.

```
meta()
```

**Description:**
Creates meta information struct.  

**Return:**  
**_Name:_**  
`value`  
**_Type:_**  
*Struct*  
**_Description:_**  
Meta information in the form `attribute = value`.  
Required attributes: `api_version`, `extra_methods`, `models`

```
create(num,model,varargin)
```

**Description:**  
Creates models of specified amount, type and initial parameters.

**Parameters:**  
**_Name:_**  
`num`  
**_Type:_**  
*Double*  
**_Description:_**  
Amount of models to be created.  
**_Name:_**  
`model`  
**_Type:_**  
*String*  
**_Description:_**  
Type of models to be created.  
**_Name:_**  
`model_params`  
**_Type:_**  
*Keyword arguments*  
**_Description:_**  
Model creation parameters.

**Return:**  
**_Name:_**  
`entity_list`  
**_Type:_**  
*Cell*  
**_Description:_**  
Structs with information about created models in the form `attribute = value`.  
Required attributes: `eid`, `type`  
Optional attributes: `rel`, `children`

```
step(time,varargin)
```

**Description:**  
Performs simulation step.

**Parameters:**  
**_Name:_**  
`time`  
**_Type:_**  
*Double*  
**_Description:_**  
Time of this simulation step.  
**_Name:_**  
`inputs`  
**_Type:_**  
*Keyword arguments*  
**_Description:_**  
Input values in the form `destination_full_id.attributes.source_full_id = value`.

**Return:**  
**_Name:_**  
`time_next_step`  
**_Type:_**  
*Double*  
**_Description:_**  
Time of next simulation step.

```
get_data(outputs)
```

**Description:**  
Receives data for requested attributes.

**Parameters:**  
**_Name:_**  
`outputs`  
**_Type:_**  

*Struct*  
**_Description:_**  
Requested attributes in the form `eid = {attribute}`.

**Return:**  
**_Name:_**  
`data`

**_Type:_**  
*Struct*  
**_Description:_**  
Requested values in the form `eid.attribute = value`.

#### MosaikUtilities

##### class MosaikAPI.Model

This is the base that you need to inherit from when just defining models. The simulator used in this case is `MosaikAPI.ModelSimulator`.

```
meta()
```

**Description:**
Creates meta information struct.  

**Return:**  
**_Name:_**  
`value`  
**_Type:_**  
*Struct*  
**_Description:_**  
Meta information in the form `attribute = value`.  
Required attributes: `public`, `attrs`, `params`  
Optional attributes: `any_inputs`

```
step(varargin)
```

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

##### class MosaikAPI.Controller

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

All simulators used in the example demos are implementations of `MosaikAPI.ModelSimulator`.  

#### ExampleSim

ExampleSim demonstrates the APIs basic functionality.  
It only has the model 'Model':  
```matlab
properties

	providedModels = {'Model'}

end
```
This model has a defined delta and current value:
```matlab
properties

	delta = 1
	val

end
```
In every step the model adds the delta value to its current value:
```matlab
function step(this,~,varargin)

	this.val = this.val + this.delta; 

end
```
While instantiating the model the initial value has to be defined:
```matlab
function this = Model(sim,eid,varargin)

	this = this@MosaikAPI.Model(sim,eid);
	
	p = inputParser;
	addOptional(p,'init_value',0,@(x)validateattributes(x,{'numeric'},{'scalar'}));
	parse(p,varargin{:});
	
	this.val = p.Results.init_value;   

end
```

#### ExampleMas

ExampleMas demonstrates the APIs advanced functionality.  
It provides the model 'Agent' which can control ExampleSims 'Model' model via asynchronous requests:
```matlab
properties

    providedModels = {'Agent'}

end
```
```matlab
properties

    rel
    val
    link	

end
```
Before executing MosaikAPIs.ModelSimulators step ExampleMas requests and displays the progress:
```matlab
function time_next_step = step(this,time,varargin)

	progress = this.mosaik.get_progress;
	disp(strcat('Progress: ',num2str(progress,2)));

	time_next_step = step@MosaikAPI.ModelSimulator(this,time,varargin{1});

end
```
Then it performs a model step in which the 'Agent' models control their related 'Model' models.  
First it obtains all related models:
```matlab
if eq(time,0)
	this.rel = this.sim.mosaik.get_related_entities(this.eid);
	disp(savejson('',this.rel));
end
```
Then it gets their current data:
```matlab
for i = 1:numel(rels)
	full_id = rels{i};
	outputs.(full_id) = {'val',[]};					
end
data = this.sim.mosaik.get_data(outputs);
disp(savejson('',data));
```
At last it sets a predefined value as the 'Model' models new input:
```matlab
for i = 1:numel(rels)
	full_id = rels{i};
	inputs.(src_full_id).(full_id).val = this.val;				
end
this.sim.mosaik.set_data(inputs);
```
There are three scenarios to test:  
Three models connected to three agents  


#### ExampleBatteryLoadSim

ExampleBatteryLoadSim simulates a battery to which various loads can be connected. The load consumes capacitance every step and feeds it back to the battery:
```matlab
rels = this.sim.mosaik.get_related_entities(this.eid);
fn_src_full_id = fieldnames(rels);
l = struct;
for j = 1:numel(fn_src_full_id)
	if strcmp(rels.(fn_src_full_id{j}).type, 'Battery')
		l.(fn_src_full_id{j}) = struct('consumed_capacitance', this.consumed_capacitance);
	end			
end
output = struct;
output.([strrep(this.sim.sid, '-', '_0x2D_'), '_0x2E_', this.eid]) = l;
this.sim.mosaik.set_data(output);
```
Based on the consumed capacitance the battery voltage decreases:
```matlab
this.capacitance = this.capacitance - this.consumed_capacitance;

this.voltage = (((this.capacitance / this.init_capacitance) ^ 0.5) * this.init_voltage);
```
There is a predefined voltage tolerance for every load and if the the voltage falls below that tolerance the load switches off for the rest of the simulation duration:
```matlab
if ge(this.voltage_in,(this.voltage*(1-this.tolerance))) && le (this.voltage_in,(this.voltage*(1+this.tolerance)))
	this.consumed_capacitance = ((this.voltage_in/this.resistance)*this.sim.step_size);
end
```


#### ExampleBatteryLoadSimControlled

ExampleBatteryLoadSimControlled is basically the same simulation as ExampleBatteryLoadSim, but the voltage calculation is done in a battery controller:
```matlab
capacitance = inputs.(this.eid).capacitance.(batteries{i});
init_capacitance = this.getValue(batteries{i},'init_capacitance');
this.voltage = (capacitance / init_capacitance)^2 * this.init_voltage;
```
The controller then decides wether the current voltage is above the shutdown voltage and calaculates consumed capacitance by the connected loads:
```matlab
if ge(this.voltage,this.shutdown_voltage)

	total_consumed_cap = 0;

	for j= 1:numel(loads)

		resistance = this.getValue(loads{j},'resistance');
		consumed_capacitance = (this.voltage / resistance) * this.step_size;

		outputs.(loads{j}).consumed_capacitance = consumed_capacitance;
		total_consumed_cap = total_consumed_cap + consumed_capacitance;

	end

	outputs.(batteries{i}).voltage = this.voltage;
	outputs.(batteries{i}).consumed_capacitance = total_consumed_cap;

end
```