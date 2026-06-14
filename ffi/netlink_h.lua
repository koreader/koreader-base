-- Automatically generated with ffi-cdecl.

require "ffi/posix_h"

require("ffi").cdef[[
static const unsigned CTRL_ATTR_FAMILY_ID = 1;
static const unsigned CTRL_ATTR_FAMILY_NAME = 2;
static const unsigned CTRL_CMD_GETFAMILY = 3;
static const unsigned GENL_ID_CTRL = 16;
static const unsigned NETLINK_CAP_ACK = 10;
static const unsigned NETLINK_GENERIC = 16;
static const unsigned NLMSG_DONE = 3;
static const unsigned NLMSG_ERROR = 2;
static const unsigned NLM_F_ACK = 4;
static const unsigned NLM_F_DUMP = 768;
static const unsigned NLM_F_DUMP_INTR = 16;
static const unsigned NLM_F_REQUEST = 1;
struct genlmsghdr {
  uint8_t cmd;
  uint8_t version;
  uint16_t reserved;
};
static const unsigned SIZEOF_GENLMSGHDR = 4;
struct nlattr {
  uint16_t nla_len;
  uint16_t nla_type;
};
static const unsigned SIZEOF_NLATTR = 4;
struct nlmsghdr {
  uint32_t nlmsg_len;
  uint16_t nlmsg_type;
  uint16_t nlmsg_flags;
  uint32_t nlmsg_seq;
  uint32_t nlmsg_pid;
};
static const unsigned SIZEOF_NLMSGHDR = 16;
struct sockaddr_nl {
  sa_family_t nl_family;
  unsigned short nl_pad;
  uint32_t nl_pid;
  uint32_t nl_groups;
};
]]
