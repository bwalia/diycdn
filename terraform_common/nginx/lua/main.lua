local client_ip			= ngx.var.remote_addr
local host_header		= ngx.var.host
local uri				    = ngx.var.uri
local uri_lc			  = uri:lower()
local params			  = ngx.var.args

local ssl				    = require "ngx.ssl"
local redis				  = require "resty.redis"
local resolver			= require "resty.dns.resolver"
local cjson				  = require "cjson"

redisEndPoint = os.getenv("REDIS_ENDPOINT")
redisEndPort = os.getenv("REDIS_PORT")

if redisEndPoint == nil then
  redisEndPoint = "127.0.0.1"
end

if redisEndPort == nil then
  redisEndPort = 6379
end
-- init headers and vars etc
local req_headers = ngx.req.get_headers()
-- checking an a header value to determine target uri
if req_headers["x-headers-debug"] == "on" then
  ngx.var.send_debug_headers = true
else 
   -- default value if not header found
end 


-- functions

function os.capture(cmd, raw) -- this function cannot be local
    local handle = assert(io.popen(cmd, 'r'))
    local output = assert(handle:read('*a'))
    
    handle:close()
    
    if raw then 
        return output 
    end
   
    output = string.gsub(
        string.gsub(
            string.gsub(output, '^%s+', ''), 
            '%s+$', 
            ''
        ), 
        '[\n\r]+',
        '<br>'
    )
   
   return output
end

-- local functions

function GetFileName(url)
  return url:match("^.+/(.+)$")
end

function GetFileExtension(url)
  return url:match("^.+(%..+)$")
end
--url:match "[^/]+$" -- To match file name
--url:match "[^.]+$" -- To match file extension
--url:match "([^/]-([^.]+))$" -- To match file name + file extension

function GetHostPortNumber(host)
  return host:match(":(.*)")
end


local function isempty(s)
  return s == nil or s == ''
end

local function find_in_str(self, str) 
    return self.find(self,str) ~= nil
end

function find_in_table(t, val)
	local r = nil
    if (type(t) ~= "table") then
        return nil
    end

 for i = 1, #t do
 	   
	 if val == t[i] then
		 return true
 	 end
 
end

    return r
end

local function starts_with(self, str) 
    return self:find('^' .. str) ~= nil
end

local function ends_with(self, str)        
    return self:find('$' .. str) ~= nil
end

function find_in_table_starts_with(t, val)
	local r = nil
    if (type(t) ~= "table") then
        return nil
    end

 for i = 1, #t do
	 if starts_with( val, t[i] ) then
		 return true
 	 end
 
end

    return r
end

local function shell_exec(cmd)
result = os.execute(cmd)
	     	return result
end

local function shell_exec_output(cmd)
result = os.capture(cmd)
return result
end

local function ip_addr_get_type(ip)
  local R = {ERROR = 0, IPV4 = 1, IPV6 = 2, STRING = 3}
  if type(ip) ~= "string" then return R.ERROR end

  -- check for format 1.11.111.111 for ipv4
  local chunks = {ip:match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")}
  if #chunks == 4 then
    for _,v in pairs(chunks) do
      if tonumber(v) > 255 then return R.STRING end
    end
    return R.IPV4
  end

  -- check for ipv6 format, should be 8 'chunks' of numbers/letters
  -- without leading/trailing chars
  -- or fewer than 8 chunks, but with only one `::` group
  local chunks = {ip:match("^"..(("([a-fA-F0-9]*):"):rep(8):gsub(":$","$")))}
  if #chunks == 8
  or #chunks < 8 and ip:match('::') and not ip:gsub("::","",1):match('::') then
    for _,v in pairs(chunks) do
      if #v > 0 and tonumber(v, 16) > 65535 then return R.STRING end
    end
    return R.IPV6
  end

  return R.STRING
end

local function host_get_ip_addr(hostname)
local ip_addr
local resolver = require "resty.dns.resolver"
            local r, err = resolver:new{
                nameservers = {"8.8.8.8", {"8.8.4.4", 53} },
                retrans = 5,  -- 5 retransmissions on receive timeout
                timeout = 2000,  -- 2 sec
            }

            if not r then
                ngx.say("failed to instantiate the resolver: ", err)
                return
            end

            local answers, err, tries = r:query(hostname, nil, {})
            if not answers then
                ngx.say("failed to query the DNS server: ", err)
                ngx.say("retry historie:\n  ", table.concat(tries, "\n  "))
                return
            end

            if answers.errcode then
                ngx.say("server returned error code: ", answers.errcode,
                        ": ", answers.errstr)
            end

     for i, ans in ipairs(answers) do
	if ip_addr_get_type(ans.address) == 'IPV4' and ip == nil then
	ip_addr = ans.address
	--ngx.say(ans.address)
	end         
  --  ngx.say(ans.name, " ", ans.address or ans.cname,"type:", ans.type, " class:", ans.class," ttl:", ans.ttl)
		end

return ip_addr
end

-- config related functions
	  
local function cfg_get_proxy_properties(cfg_prop_ref, cfg_proxy_table)
local proxy_pass_ref = cfg_prop_ref..'_pass'
local proxy_priority_ref = cfg_prop_ref..'_priority'
local backend_proxy_output_tmp, backend_priority_output_tmp = nil

for kk,vv in pairs(cfg_proxy_table) do
if kk == proxy_pass_ref then
		--ngx.say("backend_proxy_by_file_ext_pass: "..vv..'<br>')
	backend_proxy_output_tmp = vv
end

if kk == proxy_priority_ref then
		--ngx.say("backend_proxy_by_file_ext_priority: "..vv..'<br>')
	backend_priority_output_tmp = vv
end

end

return backend_proxy_output_tmp, backend_priority_output_tmp

end

-- config related functions

-- functions

-- initialise default vars



-- initialise default vars

-- redis connection open for each request

               local red = redis:new()

                red:set_timeout(1000) -- 1 sec

                local ok, err = red:connect(redisEndPoint, redisEndPort)
                
                -- local ok, err = red:connect("unix:/run/redis.sock")
               -- local ok, err = red:connect("workstation-redis-cluster-001.xg2iur.0001.euw2.cache.amazonaws.com")
                
               if not ok then
                    ngx.say("failed to connect: ", err)
                    return
                end

-- redis connection open for each request

--redis db functions
local function host_get_ip_addr_cache(hostname)
                --local ok, err = red:connect("synelastcache-001.xwlhv4.0001.euw1.cache.amazonaws.com", 6379)
                	--local ok, err = red:connect("127.0.0.1", 6379)
                local res, err = red:get(hostname..":dns_a")
                if not res then
                    ngx.say(hostname.." failed to get hostname: ", err)
                    return
                end

                if res == ngx.null then
                    ngx.say(hostname.." hostname not found.")
                    return
                end

                return res
end

local function host_set_ip_addr_cache(hostname, hostip)

                ok, err = red:setex(hostname..":dns_a", 3600, hostip)
                        if not ok then
                    ngx.say("failed to set host ip cache: ", err)
                end

end
--redis db functions

-- get proxy_upstream_host make sure it is a validate host and ip from redis otherwise display domain not found page via default

                local res, err = red:get(host_header..':host')

                if not res then
				ngx.req.set_uri('/host_not_found.html')  	--                    ngx.say(host_header..' host_not_found: ', err)
                    return

                end
					
                if res == ngx.null then
					ngx.req.set_uri('/host_not_found.html') --ngx.say(host_header..' host_not_found: ', err)
                    return
                else
					--yepeee host is found in redis OK
				ngx.var.is_a_valid_host = true
				--ngx.say("host: " , res)

				local cfg_main_table = cjson.decode(res) --convert config json to array/table
				--handle request as per the config in redis for this host
				
				-- -- -- -- --
				
		  	  local backend_proxy_output		  = ''
		  	  local backend_priority_output 	= 0
	  
		  	  --Fetch default proxy for all request types
		  	  local backend_proxy = 'proxy_pass'
		  	  local backend_proxy_port = 'proxy_pass_port'
	  
		  	  for kk,vv in pairs(cfg_main_table) do
		  	    if kk == backend_proxy then
              backend_proxy_output = vv
              ngx.var.proxy_upstream_host = backend_proxy_output
		  	    end
		  	    if kk == backend_proxy_port then
              backend_proxy_port_output = vv
              ngx.var.proxy_upstream_port = backend_proxy_port_output
              end
            end

		  	 --for loop go through config json as array/table
		  	  for cfg_key,cfg_val in pairs(cfg_main_table) do
		  	  --ngx.say('key: '..k..'<br>')
	  
		  	  --If proxy by file ext?
		  	  if string.find(cfg_key, "proxy%_by%_file%_ext%_") then
		  	  --ngx.say("Proxy by file extension is: "..k)
		  	  if type(cfg_val) == 'table' then	--Is the value an array of items?
				  -- check if the list has current ext
				local file_ext = GetFileExtension(ngx.var.uri)
				--ngx.say('file_ext:' , file_ext)
				
				if (find_in_table(cfg_val, file_ext)) then
				   --ngx.say(file_ext..' ext find_in_table:' , 'true')
	  		  	  local backend_proxy_output_tmp, backend_priority_output_tmp = cfg_get_proxy_properties(cfg_key, cfg_main_table)
				  
	  			   if ((backend_proxy_output_tmp) and (backend_priority_output_tmp) and (backend_priority_output_tmp > backend_priority_output)) then
					  backend_proxy_output = backend_proxy_output_tmp
	  			 	  ngx.var.proxy_upstream_host = backend_proxy_output
					  backend_priority_output = backend_priority_output_tmp
					  ngx.header["proxy-by-file-ext-"] = 'true'
					end
				  end
				end 
		  	  end
			  
		  	  --If proxy by url path?
		  	  if string.find(cfg_key, "proxy%_by%_url%_path%_") then
		  	  --ngx.say("Proxy by url path is: "..k..'<br>')
		  	  if type(cfg_val) == 'table' then	--Is the value an array of items?
  			    
				if (find_in_table_starts_with(cfg_val, ngx.var.uri)) then
			  			  
		  	 local backend_proxy_output_tmp, backend_priority_output_tmp = cfg_get_proxy_properties(cfg_key, cfg_main_table)
  			   if ((backend_proxy_output_tmp) and (backend_priority_output_tmp) and (backend_priority_output_tmp > backend_priority_output)) then
				  backend_proxy_output = backend_proxy_output_tmp
  			 	ngx.var.proxy_upstream_host = backend_proxy_output
				  backend_priority_output = backend_priority_output_tmp
				  ngx.header["proxy-by-url-path-"] = 'true'
				end
		  	  end
			  end 
  	  		  end
		  	  --end for loop
		  	  end
        
          if ngx.var.send_debug_headers then
            ngx.header["X-Backend-Proxy-Output"] = backend_proxy_output
            --ngx.header["X-Backend-Priority-Output"] = backend_priority_output
            --ngx.header["X-Backend-Host"] = ngx.var.proxy_upstream_host
            --ngx.var.proxy_upstream_port = GetHostPortNumber(ngx.var.proxy_upstream_host)
            --ngx.header["X-Backend-Port"] = ngx.var.proxy_upstream_port

            --ngx.header["X-Backend-Proxy-Output-Tmp"] = backend_proxy_output_tmp
            --ngx.header["X-Backend-Priority-Output-Tmp"] = backend_priority_output_tmp
            --ngx.header["X-Backend-Cache"] = "Coming soon"
            --ngx.header["Cache-Control"] = "public"
            -- -- -- -- --
          end
  
				
				end

				if ngx.var.uri and ngx.var.is_a_valid_host then
					-- rules come from redis config
					if not ip_addr_get_type(ngx.var.proxy_upstream_host) == 'IPV4' then -- we only support IPV4 or Hostnames for now
					ngx.var.proxy_upstream_host = host_get_ip_addr(ngx.var.proxy_upstream_host)
					--ngx.say(ngx.var.proxy_upstream_host..ngx.var.proxy_ip)
					end   

				end


-- or just close the connection right away:
local ok, err = red:close()
if not ok then
                     ngx.say("failed to close: ", err)
                     return
                 end
-- -- -- -- -- 

--ngx.header["X-Proxy-Host"] = ngx.var.proxy_upstream_host

