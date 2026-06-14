#include <stdint.h>
#include <sys/socket.h>
#include <linux/genetlink.h>
#include <linux/netlink.h>

cdecl_type_replace(__u8, uint8_t);
cdecl_type_replace(__u16, uint16_t);
cdecl_type_replace(__u32, uint32_t);

cdecl_type_replace(__kernel_sa_family_t, sa_family_t);

cdecl_const(CTRL_ATTR_FAMILY_ID);
cdecl_const(CTRL_ATTR_FAMILY_NAME);

cdecl_const(CTRL_CMD_GETFAMILY);

cdecl_const(GENL_ID_CTRL);

#if !defined(NETLINK_CAP_ACK)
# define NETLINK_CAP_ACK  10
#endif
cdecl_const(NETLINK_CAP_ACK);
cdecl_const(NETLINK_GENERIC);

cdecl_const(NLMSG_DONE);
cdecl_const(NLMSG_ERROR);

#if !defined(NLM_F_DUMP_INTR)
# define NLM_F_DUMP_INTR  0x10
#endif
cdecl_const(NLM_F_ACK);
cdecl_const(NLM_F_DUMP);
cdecl_const(NLM_F_DUMP_INTR);
cdecl_const(NLM_F_REQUEST);

cdecl_struct(genlmsghdr);
cdecl_sizeof(GENLMSGHDR, struct genlmsghdr);

cdecl_struct(nlattr);
cdecl_sizeof(NLATTR, struct nlattr);
cdecl_struct(nlmsghdr);
cdecl_sizeof(NLMSGHDR, struct nlmsghdr);

cdecl_struct(sockaddr_nl);
