---
v: 3

docname: draft-vilimek-yang-cbor-inst-id-latest
title: "Encoding rules of YANG 'instance-identifier' in the Concise Binary Object Representation (CBOR)"
abbrev: "yang-cbor-inst-id"
updates: RFC9254

stream: IETF
category: std
consensus: true

number:
date:
area: AREA
workgroup: WG Working Group
keyword:
 - YANG-CBOR
 - YANG
 - CBOR
venue:
  group: "Constrained RESTful Environments (CoRE)"
  type: "Working Group"
  mail: "core@ietf.org"
  github: vvilimek/draft-vilimek-yang-cbor-inst-id

author:
 - name: Vojtěch Vilímek
   org: CZ.NIC
   street: Milesovska 1136/5
   city: Praha
   code: 13000
   country: Czech Republic
   email: vojtech.vilimek@nic.cz

normative:
  RFC7950: yang
  RFC8949: cbor
  RFC9254: yang-cbor
  RFC9595: yang-sid

informative:
  RFC6241: netconf
  RFC8040: restconf
  RFC9130: isis

--- abstract

The RFC 9254 Encoding Rules of Data Modeled with YANG in the Concise Binary Object Representation (CBOR) does not
define some aspects of the encoding. Goal of this document is to fill in the gaps in the RFC 9254.
These gaps appear in encoding rules for YANG 'instance-identifier' data type.

--- middle

# Introduction

TODO Introduction


# Terminology and Notation

{::boilerplate bcp14-tagged}

The following terms are defiend in {{-yang}}:

- list

- list entry

- leaf-list

- leaf-list entry

- container

- instance-identifier

The following term is defined in {{-cbor}}:

- data item

The following terms are defined in {{-yang-cbor}}:

- delta (of YANG SIDs)

- absolute SID

The following terms are defined in {{-yang-sid}}:

- item

- YANG Schema Item iDentifier (or "YANG SID" or simply "SID")

Keyless list:
: Is config false YANG list without any keys.

Keyed list:
: Is YANG list that is not a keyless list. It is either a config true list or
  config false list with at least one key.

Note that keyless list might be inside keyed list but not vice versa. Keyless
list might be inside another keyless list, same thing holds for keyed lists.

Single instance node:
: Is a instance node with at most one possible instantiation. Instantiations of
  top-level containers are single instance nodes, instantiations of leafs of
  toplevel containers are single instance nodes. No list or leaf-list entries are
  single instance nodes, even if they have max-elements equal to one. If instance
  is a child of list entry it is not a single instance node. Note that is term is
  defined so that set of instance nodes that are uniquely identified by only YANG
  Schema Item iDentifier and set of single instance nodes are the same set.

# Representing YANG 'instance-identifier' Type in CBOR

## SIDs as 'instance-identifier'

The definitions of {{Section 6.13.1 of -yang-cbor}} applies with following
exceptions:

The encoding rules defined in the {{-yang-cbor}} for list apply only to keyed lists.

In the case of a representation node that is an entry of a keyless list, a SID
is combined with the list entry index is used to identify each instance within the
keyless list. The index MUST be encoded using CBOR unsigned integer data item
(major type 0). The index is 1-base to keep same indexing base as RESTCONF
{{-restconf}} and NETCONF {{-netconf}}.

Instance-identifier of leaf-list entry with single instance parent MUST be
encoded using a two-element CBOR array item (major type 4) containing the
following CBOR data items:

- The first element MUST be encoded as a CBOR unsigned integer data item (major
  type 0) and set to the targeted schema node SID.

- The second element MUST be encoding of the leaf-list entry value as defined by
  this document or as defined by {{-yang-cbor}}.

Instance-identifier of leaf-list with single instance node parent MUST be
encoded using a CBOR unsigned integer set to targeted schema node SID.

Instance-identifier of leaf-list entry, if entry's parent is not a single
instance node, MUST be encoded using a CBOR array data item (major type 4)
containing the following entries:

- The first entry array MUST be encoded as a CBOR unsigned integer
  data item (major type 0) and set to the targeted schema node SID.

- The following entries MUST contain the value of each key required to identify
  the instance of the targeted schema node. These keys MUST be ordered as defined
  in the 'key' YANG statement, staring from the top-level list, and the followed
  by each subordinate lists(s).

- The last entry MUST be encoded according to rules defined for the targeted
  node data type. These rules are defined in {{-yang-cbor}}.

Instance-identifier of leaf-list with parent that is not a single instance node
MUST be encoded using a CBOR array data item (major type 4) containing the
following entries:

- The first entry MUST be encoded as a CBOR unsigned integer data item (major
  type 0) and set to the targeted schema node SID.

- The following entries MUST contain the value of each key required to identify
  the instance of the targeted schema node. These keys MUST be ordered as defined
  in the 'key' YANG statement, starting from the top-level list, and follow by
  each subordinate list(s).

Definition example adapted from {{-yang}}:

~~~ yang
container system {
  ...
  leaf reporting-entity {
    type instance-identifier;  
  }
}
~~~

YANG model code snippet used for second and third example:

~~~ yang
container auth {
  leaf-list foreign-user {
    type string;
  }
}
~~~

*First example:*
The following example shows the encoding of the 'reporting-entity' value
referencing keyless list "/adjacencies/adjacency" (which is assumed to have SID 68000) for second list entry. The example
adapted from {{-isis}}:

~~~ yang
container adjacencies {
  config false;
  list adjacency {
    leaf neighbor-sysid {
      type string;
    }
  }
}
~~~

CBOR diagnostic notation: `[68000, 2]`

CBOR encoding:
~~~ cbor-pretty
82 # array(2)
   1A 000109A0 # 68000
   02 # 2
~~~

The equivalent RESTCONF resource identifier is "".

*Second example:*

The following example shows the encoding of the 'reporting-entity' value referencing leaf-list instance "/auth/foreign-user" (which is assumed to have SID 60000)
entry "alice".

CBOR diagnostic notation: `[ 60000, "alice" ]`

CBOR encoding:
~~~ cbor-pretty
82               # array(2)
   19 F6F6       # unsigned(60000)
   65            # text(5)
      616c696365 # "alice"
~~~

*Third example:*

The following example show the encoding of the 'reporting-entity' value referencing leaf-list instance "/auth/foreign-user" (SID 60000).

CBOR diagnostic notation: `60000`

CBOR encoding: `19 F6F6`

*Fourth example:*
The following example shows the encoding of the 'reporting-entity' value referencing leaf-list instance "/user-group/user" (which is assumed to have SID 61000) entry "eve" for group-name "restricted".

~~~ yang
list user-group {
  config true;
  key "name"

  leaf group-name {
    type string;
  }

  leaf-list user {
    type string;
  }
}
~~~

CBOR diagnostic notation: `[ 61000, "restricted", "eve" ]` 

CBOR encoding:
~~~ cbor-pretty
83   # array(3) 
   19 EE48  # 61000
   6A # text(10)
      72657374726963746564 # "resricted"
   63 # text(3)   
      657665 # "eve"
~~~


*Fifth example:*

The following example shows the encoding of 'reporting-entity' value referencing leaf-list instance "/user-group/user" for group name "restricted".

CBOR diagnostic notation: `[ 61000, "restricted" ]`

CBOR encoding:
~~~ cbor-pretty
83   # array(3) 
   19 EE48 # 61000
   6A # text(10)
      72657374726963746564 # "resricted"
~~~

Note that this encoding is same as if the node user was a leaf.

*Sixth example:*

The following example shows the encoding of 'reporting-entity' value referencing leaf-list instance "/working-group/chair" entry. This entry references "/auth/foreign-user" leaf-list entry "John Smith".
The "/working-group/chair" is assumed to have SID 62000.

~~~ yang
list working-group {
  leaf name {
    type string;
  }

  leaf-list chair {
    type instance-identifier;
  }
}
~~~

CBOR diagnostic notation: `[ 62000, "core", [ 60000, "John Smith" ] ]`

CBOR encoding:
~~~ cbor-pretty
83 # array(3)
   19 F230 # 62000
   64 # text(4)
      636F7265 # "core" 
   82 # array(2)
      19 F6F6 # 60000
      6A # text(10)
         4a6f686e20536d697468 # "John Smith"
~~~

# Content-Types
TODO check again that application/yang-data+cbor id=sid may not use instance-identifier encoded using Names {{Section 6.13.2 of -yang-cbor}}.

# Security Considerations

The security considerations of {{-cbor}}, {{-yang}}, {{-yang-cbor}} and {{-yang-sid}} apply.

TODO Security


# IANA Considerations

<!--
This document has no IANA actions.
-->

TODO note about changes (unfortunately this document will have an IANA action)


--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge. thank Andy Bierman for his friendly responses on mailing list.
