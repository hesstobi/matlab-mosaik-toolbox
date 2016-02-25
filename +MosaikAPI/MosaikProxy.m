classdef MosaikProxy < handle
	% MOSAIKPROXY   Asynchronous request proxy for MOSAIK.
	%   Provides asynchronous communication between simulator and MOSAIK. 

	properties

		sim  % Associated simulator.

	end

	methods

		function this = MosaikProxy(simulator)
			% Constructor of the class MosaikProxy.
			%
			% Parameter:
			%
			%  - simulator: Simulator argument; associated simulator
			%                                   instance.
			%
			% Return:
			%
			%  - this: MosaikProxy object.

			this.sim = simulator;

		end

		function progress = get_progress(this)
			% Returns 'get_progress' message for MOSAIK.
			%
			% Parameter:
			%
			%  - none
			%
			% Return:
			%
			%  - this: Double object; progress.

			content{1} = 'get_progress';
			content{2} = {};
			content{3} = struct;
			progress = this.sim.socket.sendRequest(content);

		end
		
		function related_entities = get_related_entities(this,entities)
			% Returns 'get_related_entities' message for MOSAIK.
			%
			% Parameter:
			%
			%  - entites: String or cell argument; model eid or model eids
			%             or full eids
            %               
			%
			% Return:
			%
			%  - related_entities: Struct object; (source entitiy and) related entities.
			
            if ischar(entities)
                entities = {entities};
            end        
                       
            simpleIds = and(cellfun(@isempty,strfind(entities,'.')),cellfun(@isempty,strfind(entities,'_0x2E_')));                 
            entities(simpleIds) = strcat(this.sim.sid,'.',entities(simpleIds));
                    
			content{1} = 'get_related_entities';        
			content{2} = entities;
			content{3} = struct;

            related_entities = this.sim.socket.sendRequest(content);

		end
		
		function data = get_data(this,attrs)
			% Returns 'get_data' message for MOSAIK.
			%
			% Parameter:
			%
			%  - attrs: Struct argument; full ids and requested
			%                               attributes.
			%
			% Return:
			%
			%  - data: Struct object; fulls ids, requested attributes
			%                         and its values.
			 
			content{1} = 'get_data';
			content{2} = {attrs};
			content{3} = struct;

			data = this.sim.socket.sendRequest(content);

		end
		
		function set_data(this,data)
			% Returns 'set_data' message for MOSAIK.
			%
			% Parameter:
			%
			%  - data: Struct object; source full ids, destination
			%                             full ids, attributes and values
			%
			% Return:
			%
			%  - none
			
			content{1} = 'set_data';
			content{2} = {data};
			content{3} = struct;

			this.sim.socket.sendRequest(content);
			
		end

	end

end
