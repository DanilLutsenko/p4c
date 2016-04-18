#include "/home/cdodd/p4c/build/../p4include/core.p4"
#include "/home/cdodd/p4c/build/../p4include/v1model.p4"

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> ethertype;
}

header my_tag_t {
    bit<32> bd;
    bit<16> ethertype;
}

header vlan_tag_t {
    bit<3>  pcp;
    bit<1>  cfi;
    bit<12> vlan_id;
    bit<16> ethertype;
}

struct metadata {
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
    @name("my_tag") 
    my_tag_t   my_tag;
    @name("vlan_tag") 
    vlan_tag_t vlan_tag;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_my_tag") state parse_my_tag {
        packet.extract(hdr.my_tag);
        transition select(hdr.my_tag.ethertype) {
            16w0x8100 &&& 16w0xefff: parse_vlan_tag;
            default: accept;
        }
    }
    @name("parse_vlan_tag") state parse_vlan_tag {
        packet.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ethertype) {
            16w0x9000: parse_my_tag;
            default: accept;
        }
    }
    @name("start") state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.ethertype) {
            16w0x8100 &&& 16w0xefff: parse_vlan_tag;
            16w0x9000: parse_my_tag;
            default: accept;
        }
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("nop") action nop() {
        bool hasReturned_1 = false;
    }
    @name("t2") table t2() {
        actions = {
            nop;
            NoAction;
        }
        key = {
            hdr.ethernet.srcAddr: exact;
        }
        default_action = NoAction();
    }

    apply {
        bool hasReturned_0 = false;
        t2.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("nop") action nop() {
        bool hasReturned_3 = false;
    }
    @name("t1") table t1() {
        actions = {
            nop;
            NoAction;
        }
        key = {
            hdr.ethernet.dstAddr: exact;
        }
        default_action = NoAction();
    }

    apply {
        bool hasReturned_2 = false;
        t1.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        bool hasReturned_4 = false;
        packet.emit(hdr.ethernet);
        packet.emit(hdr.vlan_tag);
        packet.emit(hdr.my_tag);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
        bool hasReturned_5 = false;
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        bool hasReturned_6 = false;
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;