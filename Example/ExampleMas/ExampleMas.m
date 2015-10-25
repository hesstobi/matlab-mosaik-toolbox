classdef ExampleMas < MosaikAPI.Simulator
	% EXAMPLEMAS   Simulator to demonstrate async requests.
	%   Demonstrates all asynchronous request methods with ExampleSim model.

	properties (Access=private)
		agents = {};
	end

	properties (Constant)
		model = 'Agent';
	end

	properties
		val;
		rel;
		step_size;
	end

	methods

		function this = ExampleMas(varargin)
			this = this@MosaikAPI.Simulator(varargin{:});
		end

		function value = meta(this)
            % Creates meta struct and adds collector meta content.

            value = meta@MosaikAPI.Simulator(this);
            
            value.extra_methods = {};
            
            value.models.(this.model).public = true;
            value.models.(this.model).attrs = {'link',[]};
            value.models.(this.model).params = {'val',[]};
            value.models.(this.model).any_inputs = true;
            
        end

		function agents = create(this,num,model,varargin)

			if ~strcmp(model,'Agent')
				error('Can only create "Agent" models.');
			end

			p = inputParser;
            addOptional(p,'val',10,@(x)validateattributes(x,{'numeric'},{'scalar'}));
            parse(p,varargin{:});

			% Add all created agent models to agent array.
			num_agents = numel(this.agents);
			agents = {};
			for i = num_agents:num_agents+num-1
				l.eid = num2str(i);
				l.type = model;
				l.rel = {};
				l.val = p.Results.val; 
				agents(end+1) = {l};
			end

			this.agents = horzcat(this.agents,agents);
			if eq(numel(agents),1)
				agents(end+1) = {[]};
			end
		end

		function time_next_step = step(this,time,varargin)
			progress = this.mosaik.get_progress;
			disp(strcat('Progress: ',num2str(progress,2)));

			if eq(time,0)
				agents = cellfun(@(x) strcat(this.sid,'.',x.eid),this.agents,'UniformOutput',false);
				this.rel = this.mosaik.get_related_entities(agents);
				disp(savejson('',this.rel));
			end

			rels = fieldnames(this.rel);

			outputs = struct;
			if eq(numel(rels),1)
				full_id = rels{1};

				% Replace unallowed symbols from sid.eid string
				full_id = strrep(full_id,'.','_0x2E_');
				full_id = strrep(full_id,'-','_0x2D_');
					
				outputs.(full_id) = {'val',[]};
				data = this.mosaik.get_data(outputs);

				disp(savejson('',data));

										inputs = struct;
										full_id = fieldnames(this.rel);
										for i = 1:numel(full_id)
											a = this.agents{i};
											src_full_id = strcat(this.sid,'.',a.eid);
											src_full_id = strrep(src_full_id,'.','_0x2E_');
											src_full_id = strrep(src_full_id,'-','_0x2D_');
											for j = 1:numel(src_full_id)
												inputs.(this.rel.(full_id){i}).(full_id).val = this.val;
											end
										end
										this.mosaik.set_data(inputs);
			else
				for i = 1:numel(rels)
					rel = this.rel.(rels{i});
					full_ids = fieldnames(rel);
					for j = 1:numel(full_ids)
						full_id = full_ids{j};

						% Replace unallowed symbols from sid.eid string
						full_id = strrep(full_id,'.','_0x2E_');
						full_id = strrep(full_id,'-','_0x2D_');
						
						outputs.(full_id) = {'val',[]};
					end
				end
				data = this.mosaik.get_data(outputs);

				disp(savejson('',data));

				inputs = struct;
				for i = 1:numel(rels)
					src_full_id = rels{i};
					src_full_id = strrep(src_full_id,'.','_0x2E_');
					src_full_id = strrep(src_full_id,'-','_0x2D_');
					dest_full_ids = fieldnames(this.rel.(src_full_id));
					for j = 1:numel(full_ids)
						inputs.(src_full_id).(dest_full_ids{j}).val = this.val;
					end
				end
				this.mosaik.set_data(inputs);
			end

			time_next_step = time + this.step_size;
		end

		function data = get_data(this,outputs)
			% Returns empty cell array.

			data = {};
		end

	end

end
