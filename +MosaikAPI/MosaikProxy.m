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
			content{2} = {{}};
			content{3} = struct;
			progress = this.sim.socket.sendRequest(content);

		end
		
		function related_entities = get_related_entities(this,varargin)
			% Returns 'get_related_entities' message for MOSAIK.
			%
			% Parameter:
			%
			%  - varargin: String or cell argument; model eid or model eids.
			%
			% Return:
			%
			%  - related_entities: Struct object; (source entitiy and) related entities.
			
			content{1} = 'get_related_entities';        
			if gt(nargin,1)
				if ischar(varargin{1})
					varargin =  strcat(this.sim.sid,'.',cellstr(varargin{1}));
				end
				varargin{end+1} = {[]};
			else
				varargin{end+1} = {{}};
			end
			content{2} = varargin;
			content{3} = struct;
			related_entities = this.sim.socket.sendRequest(content);

		end
		
		function data = get_data(this,varargin)
			% Returns 'get_data' message for MOSAIK.
			%
			% Parameter:
			%
			%  - varargin: Struct argument; full ids and requested
			%                               attributes.
			%
			% Return:
			%
			%  - data: Struct object; fulls ids, requested attributes
			%                         and its values.
			
			content{1} = 'get_data';
			if iscell(varargin{1})
				varargin =  varargin{1};
			else
				varargin{end+1} = {[]};
			end
			content{2} = varargin;
			content{3} = struct;
			data = this.sim.socket.sendRequest(content);

		end
		
		function set_data(this,varargin)
			% Returns 'set_data' message for MOSAIK.
			%
			% Parameter:
			%
			%  - varargin: Struct object; source full ids, destination
			%                             full ids, attributes and values
			%
			% Return:
			%
			%  - none
			
			content{1} = 'set_data';
			if iscell(varargin{1})
				varargin =  varargin{1};
			else
				varargin{end+1} = {[]};
			end
			content{2} = varargin;
			content{3} = struct;
			this.sim.socket.sendRequest(content);
			
		end

	end

end
