classdef Simulator < MosaikAPI.SimSocketDelegate

	properties
		api_version = 2;
		meta = struct;
		delegator;
	end

	methods

		function sim = Simulator(server, meta)
			% this = Simulator(server)
			% Constructor of the class Simulator
			%
			% Parameter:
			%  - server  : Server IP and port as char, format: 'IP:port'
			%
			% Return:
			%  - sim: Simulator Object            

			%Error when server is not a string
			assert(ischar(server), 'Wrong server configuration. Check server configuration.')

			%Get server from mosaik and start tcpclient at given host and port.
			assert(~isempty(strfind(server,':')), 'Wrong server configuration. Check server configuration.')
			[ip,port] = parse_address(sim,server);

			sim.meta = meta;
			sim.meta.('api_version') = sim.api_version;

			%Creates socket and starts main loop
			MosaikAPI.SimSocket(ip,port,sim);
		end

	end

	methods
				
		function response = delegate(sim,request) 
			%Parses request and calls simulator function.
			func = request{1};
			func = str2func(func);
			response = func(sim,request{2:end});
		end

	end

	methods (Access=private)
		
		function null = setup_done(~)
			%Returns empty response.
			null = [];
		end
		
		function [ip, port] = parse_address(~, server)
			%Parses address string. Returns ip as string and port as integer.
			server = strsplit(server,':');
			if ~isempty(server(1))
				ip = server{1};
			else
				error('No server IP entered. Check server configuration.')
			end
			if ~isempty(server(2))
				port = server(2);
				port = str2double(port{:});
				assert(isnumeric(port), 'Wrong server port. Check server configuration.')
			else
				error('No server port entered. Check server configuration.')
			end
		end

	end

	methods %(Access = protected)
	
		function set_delegator(sim, delegator)
			sim.delegator = delegator;
		end

		function stop = stop(~, ~, ~)
			stop = ('stop');
		end

		function progress = as_get_progress(sim)
			content{1} = 'get_progress';
			content{2} = {};
			content{3} = struct;
			progress = sim.delegator.send_request(content);
		end

		% To return an empty list, JSONlab needs an empty cell in that cell: {{}}
		% To return a list with one element, JSONlab needs a second element, an empty array in that cell: {'example',[]}
		% JSONlab converts them to null, which is removed in SimSocket.serialize(~,~,~).
		function related_entities = as_get_related_entities(sim, varargin)
			content{1} = 'get_related_entities';
			if gt(nargin,1)
				if ischar(varargin{1})                
				   varargin =  cellstr(varargin{1});
				end
				varargin{end+1} = {[]};
			else
				varargin{end+1} = {{}};
			end
			content{2} = varargin;
			content{3} = struct;
			related_entities = sim.delegator.send_request(content);
		end

		function data = as_get_data(sim, varargin)
			content{1} = 'get_data';
			if iscell(varargin{1})                
				varargin =  varargin{1};
			else
				varargin{end+1} = {[]};
			end
			content{2} = varargin;
			content{3} = struct;
			data = sim.delegator.send_request(content);
		end

		function as_set_data(sim, varargin)
			content{1} = 'set_data';
			if iscell(varargin{1})                
				varargin =  varargin{1};
			else
				varargin{end+1} = {[]};
			end
			content{2} = varargin;
			content{3} = struct;
			sim.delegator.send_request(content);
		end

	end


	%Methods the simulator needs to inherit from.
	methods (Abstract)

		init(sim,args,kwargs);

		create(sim,args,kwargs);
		
		step(sim,args,kwargs);

		get_data(sim,args,kwargs);
		
	end
end
