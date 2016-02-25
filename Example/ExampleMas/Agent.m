classdef Agent < MosaikAPI.Model
	% AGENT   Example agent model for ExampleMas
	%   Simple agent model that defines other models input value.
	
	properties

		rel		% Related models
		val		% Constant output value
		link	% Connecting attribute

	end

	methods 

		function this = Agent(sim,eid,varargin)
			% Constructor of the class Agent
			%
			% Parameter:
			%  - sim: Related simulator
			%  - eid: Model entity ID
			%  - varargin: Unspecified model parameters.
			%
			% Return:
			%  - this: Agent object

			this = this@MosaikAPI.Model(sim,eid);

			p = inputParser;
			addOptional(p,'val',10,@(x)validateattributes(x,{'numeric'},{'scalar'}));
			parse(p,varargin{:});

			this.val = p.Results.val;     

		end

		function step(this,time,varargin)
			% Checks for related models, gets their current data and sets a new input.

			% Receives all related models.
			if eq(time,0)
				this.rel = this.sim.mosaik.get_related_entities(this.eid);
				disp(savejson('',this.rel));
			end

			rels = fieldnames(this.rel);
			outputs = struct;
			inputs = struct;

			% Gets data from related models.
			for i = 1:numel(rels)
				full_id = rels{i};
				outputs.(full_id) = {'val'};					
			end
			data = this.sim.mosaik.get_data(outputs);
			disp(savejson('',data));

			% Creates source id string, replace invalid symbols.
			src_full_id = strcat(this.sim.sid,'.',this.eid);
			src_full_id = strrep(src_full_id,'.','_0x2E_');
			src_full_id = strrep(src_full_id,'-','_0x2D_');

			% Sets data for related models.
			for i = 1:numel(rels)
				full_id = rels{i};
				inputs.(src_full_id).(full_id).val = this.val;				
			end
			this.sim.mosaik.set_data(inputs);

		end       

	end

	methods (Static)

		function value = meta()
			% Adds model meta content to meta struct.

			value.public = true;
			value.attrs = {'link'};
			value.params = {'val'};
			value.any_inputs = true;
			
		end

	end

end
