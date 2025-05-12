-- SitePackage.lua
-- Hutch LMOD logging
-- June 2020  John Dey
-- May 2025 John Dey 
--  'top' is reserved word

require("strict")
require("cmdfuncs")
require("utils")
require("lmod_system_execute")

local FrameStk  = require("FrameStk")
local hook = require("Hook")

function load_hook(t)
    if (mode() ~= "load") then return end

    local user = os.getenv("USER")
    local jobid = os.getenv("SLURM_JOB_ID")
    local sep = "/"
    local mod={}
    for str in string.gmatch(t.modFullName, "([^"..sep.."]+)") do
	       table.insert(mod,str)
    end

    -- if userload is yes, the user requested to load this module. Else
    -- it is getting loaded as a dependency.
    local frameStk = FrameStk:singleton()
    local userload = (frameStk:atTop()) and "yes" or "no"
    local msg = string.format("mesg=LMOD module=%s, name=%s, head=%s, user=%s, jobid=%s",
                              t.modFullName,mod[1],userload,user,jobid)

    lmod_system_execute("logger -t LMOD -p local0.info " .. msg)
end

hook.register("load",load_hook)

local function errwarnmsg_hook(kind, key, msg, t)
	    -- kind is either lmoderror, lmodwarning or lmodmessage
	    -- key is a unique key for the message (see messageT.lua)
	    -- msg is the actual message to display (as string)
	    -- t is a table with the keys used in msg
	    dbg.start{"errwarnmsg_hook"}

            if key == "e_No_AutoSwap" then
	        -- find the module name causing the issue (almost always toolchain module)
	        local sname = t.sn
	        local frameStk = FrameStk:singleton()

                local errmsg = {"A different version of the '"..sname.."' module is already loaded (see output of 'ml')."}
	        if not frameStk:empty() then
	            local compat_msg = "' module for that is compatible with the currently loaded version of '"
	            errmsg[#errmsg+1] = "You should load another '"..frameStk:sn()..compat_msg..sname.."'."
	            errmsg[#errmsg+1] = "Use 'ml spider "..frameStk:sn().."' to get an overview of the available versions."
	        end
	        errmsg[#errmsg+1] = "\n"

	        msg = table.concat(errmsg, "\n")
	    end

            if kind == "lmoderror" or kind == "lmodwarning" then
	        msg = msg .. "\nIf you don't understand the warning or error, contact the helpdesk"
	    end
	    
	    dbg.fini()

	    return msg
end
