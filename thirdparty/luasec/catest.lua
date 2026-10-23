local ssl = require "ssl"
local https = require "ssl.https"
local util = require "util"

local CA_FILE = nil

local GH_MD = false

local GH_COLOR = {
    blue           = "$${\\color{blue}",
    green          = "$${\\color{green}",
    green_bright   = "$${\\color{limegreen}",
    magenta        = "$${\\color{violet}",
    magenta_bright = "$${\\color{magenta}",
    red            = "$${\\color{red}",
    red_bright     = "$${\\color{crimson}",
    reset          = "}$$",
}

local ANSI_COLOR = {
    blue           = "\x1b[34m",
    green          = "\x1b[32m",
    green_bright   = "\x1b[32;1m",
    magenta        = "\x1b[35m",
    magenta_bright = "\x1b[35;1m",
    red            = "\x1b[31m",
    red_bright     = "\x1b[31;1m",
    reset          = "\x1b[0m",
}

local COLOR

local TRY_CURL, TRY_LUASEC = true, true

local function colored_info(class, info)
    local color
    if class == "good" then
        color = COLOR.green
    elseif class == "dubious" then
        color = COLOR.magenta
    else
        color = COLOR.red
    end
    local text = color..class..(info and string.format(" [%s]", info) or "")..COLOR.reset
    if GH_MD then
        text = text:gsub(" ", "\\space ")
    end
    return text
end

local function colored_result(class, result)
    local success = (class == "good") == result
    local color
    if class == "dubious" then
        color = success and COLOR.green_bright or COLOR.magenta_bright
    else
        color = success and COLOR.green_bright or COLOR.red_bright
    end
    return color..(success and "SUCCESS" or "FAIL")..COLOR.reset
end

local function colored_status(status)
    return GH_MD and ("`"..status.."`") or status
end

local filters = {}
local next_arg = (function ()
    local n = 0
    return function()
        n = n + 1
        return arg[n]
    end
end)()
for a in next_arg do
    if a:match("^[-]") then
        if a == "--ca-file" then
            CA_FILE = next_arg()
        elseif a == "--gh-md" then
            GH_MD = true
        elseif a == "--no-curl" then
            TRY_CURL = false
        elseif a == "--no-luasec" then
            TRY_LUASEC = false
        else
            error("invalid option: "..a)
        end
    else
        table.insert(filters, a)
    end
end
COLOR = GH_MD and GH_COLOR or ANSI_COLOR

if CA_FILE then
    local ca_file = CA_FILE
    if ca_file == "false" then
        ca_file = false
    elseif ca_file == "nil" then
        ca_file = nil
    end
    ssl.set_system_ca(ca_file)
end

local tmpfile = os.tmpname()

for _, test in ipairs{

    -- badssl.com
    {class="good"   , info="valid"                               , url="https://badssl.com/"                         },
    --
    {class="bad"    , info="cert: expired"                       , url="https://expired.badssl.com/"                 },
    {class="bad"    , info="cert: wrong host"                    , url="https://wrong.host.badssl.com/"              },
    {class="bad"    , info="cert: self-signed"                   , url="https://self-signed.badssl.com/"             },
    {class="bad"    , info="cert: untrusted-root"                , url="https://untrusted-root.badssl.com/"          },
    {class="bad"    , info="cert: revoked"                       , url="https://revoked.badssl.com/"                 },
    -- {class="bad"    , info="cert: pinning-test"                  , url="https://pinning-test.badssl.com/"            },
    --
    {class="dubious", info="cert: no-common-name"                , url="https://no-common-name.badssl.com/"          },
    {class="dubious", info="cert: no-subject"                    , url="https://no-subject.badssl.com/"              },
    {class="dubious", info="cert: incomplete-chain"              , url="https://incomplete-chain.badssl.com/"        },
    --
    {class="good"   , info="cert: sha256"                        , url="https://sha256.badssl.com/"                  },
    {class="good"   , info="cert: sha384"                        , url="https://sha384.badssl.com/"                  },
    {class="good"   , info="cert: sha512"                        , url="https://sha512.badssl.com/"                  },
    --
    {class="good"   , info="cert: 1000-sans"                     , url="https://1000-sans.badssl.com/"               },
    {class="good"   , info="cert: 10000-sans"                    , url="https://10000-sans.badssl.com/"              },
    --
    {class="good"   , info="cert: ecc256"                        , url="https://ecc256.badssl.com/"                  },
    {class="good"   , info="cert: ecc384"                        , url="https://ecc384.badssl.com/"                  },
    --
    {class="good"   , info="cert: rsa2048"                       , url="https://rsa2048.badssl.com/"                 },
    {class="good"   , info="cert: rsa4096"                       , url="https://rsa4096.badssl.com/"                 },
    {class="dubious", info="cert: rsa8192"                       , url="https://rsa8192.badssl.com/"                 },
    --
    {class="good"   , info="cert: extended-validation"           , url="https://extended-validation.badssl.com/"     },
    --
    {class="dubious", info="cipher: cbc"                         , url="https://cbc.badssl.com/"                     },
    {class="bad"    , info="cipher: rc4-md5"                     , url="https://rc4-md5.badssl.com/"                 },
    {class="bad"    , info="cipher: rc4"                         , url="https://rc4.badssl.com/"                     },
    {class="bad"    , info="cipher: 3des"                        , url="https://3des.badssl.com/"                    },
    {class="bad"    , info="cipher: null"                        , url="https://null.badssl.com/"                    },
    {class="bad"    , info="cipher: mozilla-old"                 , url="https://mozilla-old.badssl.com/"             },
    {class="dubious", info="cipher: mozilla-intermediate"        , url="https://mozilla-intermediate.badssl.com/"    },
    {class="good"   , info="cipher: mozilla-modern"              , url="https://mozilla-modern.badssl.com/"          },
    --
    {class="bad"    , info="key: dh480"                          , url="https://dh480.badssl.com/"                   },
    {class="bad"    , info="key: dh512"                          , url="https://dh512.badssl.com/"                   },
    {class="bad"    , info="key: dh1024"                         , url="https://dh1024.badssl.com/"                  },
    {class="dubious", info="key: dh2048"                         , url="https://dh2048.badssl.com/"                  },
    {class="bad"    , info="key: dh-small-subgroup"              , url="https://dh-small-subgroup.badssl.com/"       },
    {class="bad"    , info="key: dh-composite"                   , url="https://dh-composite.badssl.com/"            },
    {class="dubious", info="key: static-rsa"                     , url="https://static-rsa.badssl.com/"              },
    --
    {class="dubious", info="protocol: tls-v1-0"                  , url="https://tls-v1-0.badssl.com:1010/"           },
    {class="dubious", info="protocol: tls-v1-1"                  , url="https://tls-v1-1.badssl.com:1011/"           },
    {class="good"   , info="protocol: tls-v1-2"                  , url="https://tls-v1-2.badssl.com:1012/"           },
    --
    {class="bad"    , info="cert: no-sct"                        , url="https://no-sct.badssl.com/"                  },
    --
    {class="good"   , info="upgrade"                             , url="https://upgrade.badssl.com/"                 },
    {class="good"   , info="upgrade: hsts"                       , url="https://hsts.badssl.com/"                    },
    -- {class="good"   , info="upgrade: preloaded-hsts"             , url="https://preloaded-hsts.badssl.com/"          },
    {class="bad"    , info="upgrade: subdomain.preloaded-hsts"   , url="https://subdomain.preloaded-hsts.badssl.com/"},
    --
    {class="good"   , info="UI: long-extended-subdomain-name-containing-many-letters-and-dashes", url="https://long-extended-subdomain-name-containing-many-letters-and-dashes.badssl.com/"},
    {class="good"   , info="UI: longextendedsubdomainnamewithoutdashesinordertotestwordwrapping", url="https://longextendedsubdomainnamewithoutdashesinordertotestwordwrapping.badssl.com/"},
    --
    {class="bad"    , info="known bad: (Lenovo) Superfish"       , url="https://superfish.badssl.com/"               },
    {class="bad"    , info="known bad: (Dell) eDellRoot"         , url="https://edellroot.badssl.com/"               },
    {class="bad"    , info="known bad: (Dell) DSD Test Provider" , url="https://dsdtestprovider.badssl.com/"         },
    {class="bad"    , info="known bad: preact-cli"               , url="https://preact-cli.badssl.com/"              },
    {class="bad"    , info="known bad: webpack-dev-server"       , url="https://webpack-dev-server.badssl.com/"      },
    --
    {class="bad"    , info="chrome: captive-portal"              , url="https://captive-portal.badssl.com/"          },
    {class="bad"    , info="chrome: mitm-software"               , url="https://mitm-software.badssl.com/"           },
    --
    {class="dubious", info="defunct: sha1-2016"                  , url="https://sha1-2016.badssl.com/"               },
    {class="bad"    , info="defunct: sha1-2017"                  , url="https://sha1-2017.badssl.com/"               },
    {class="bad"    , info="defunct: sha1-intermediate"          , url="https://sha1-intermediate.badssl.com/"       },
    {class="bad"    , info="defunct: invalid-expected-sct"       , url="https://invalid-expected-sct.badssl.com/"    },

    -- https://emudhra.we-have-a-problem.com/.
    {class = "bad", info = "cert: revoked"       , url = "https://dv-g3b-emudhra.we-have-a-problem.com/"    },
    {class = "bad", info = "cert: unknown issuer", url = "https://dv-g3b-aaa-emudhra.we-have-a-problem.com/"},

} do
    local match
    if #filters == 0 then
        match = true
    else
        for _, f in ipairs(filters) do
            if test.info:find(f, 1, true) or test.url:find(f, 1, true) then
                match = true
                break
            end
        end
    end
    if not match then goto continue end
    io.stdout:write(GH_MD and "- " or "")
    print(colored_info(test.class, test.info), GH_MD and test.url or (COLOR.blue..test.url..COLOR.reset))
    if TRY_CURL then
        local cmd = {
            "curl",
            "--show-error", "--show-headers",
            "--silent",
        }
        local ca_file = ssl.get_system_ca()
        if ca_file then
            util.arrayAppend(cmd, {"--cacert", ca_file})
        end
        table.insert(cmd, test.url)
        local ok = os.execute(util.shell_escape(cmd)..">'"..tmpfile.."' 2>&1")
        local fp = io.open(tmpfile)
        local out = fp:read()
        out = out:match("[^\r]*")
        fp:close()
        io.stdout:write(GH_MD and "  * " or "\t")
        print("curl", colored_result(test.class, ok == 0), colored_status(ok == 0 and out or ("ERROR "..out)))
    end
    if TRY_LUASEC then
        local ok, status, _, status_line = https.request{url = test.url}
        io.stdout:write(GH_MD and "  * " or "\t")
        print("luasec", colored_result(test.class, ok ~= nil), colored_status(ok and status_line or ("ERROR "..status)))
    end
    ::continue::
end

os.remove(tmpfile)
