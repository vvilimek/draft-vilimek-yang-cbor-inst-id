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
  RFC7951: yang-json
  RFC8040: restconf
  RFC9130: isis

--- abstract

Encoding rules of YANG-CBOR {{-yang-cbor}} are incomplete for
'instance-identifier' YANG data type. This document defines missing encoding
rules for this data type.

--- middle

# Introduction

The RFC 9254 Encoding Rules of Data Modeled with YANG in the Concise Binary
Object Representation (CBOR) does not define encoding rules for
'instance-identifier' pointing to list without keys entry instances and
instances of leaf-list entries. The goal of this document is to define the
missing rules and make clarifications in the used terminology.

# Terminology and Notation

{::boilerplate bcp14-tagged}

The following terms are defiend in {{-yang}}:

- list
- leaf-list
- leaf
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

Note that the {{-yang-cbor}} also define term YANG Schema Item iDentifier but the definition describe the same term.

TODO: use the "The following terms are used within this document:" header?

Keyless list:
: Is config false YANG list without any keys.

Keyed list:
: Is YANG list that is not a keyless list. It is either a config true list or
  config false list with at least one key.

Single instance node:
: Is a instance node with at most one possible instantiation. Instantiations of
  top-level containers are single instance nodes, instantiations of leafs of
  toplevel containers are single instance nodes. Container and leaf
  instantiations of single instance node are also single instance nodes. No list
  or leaf-list entries are
  single instance nodes, even if they have max-elements equal to one. If instance
  is a child of list entry it is not a single instance node. Note that this term is
  defined so that set of instance nodes that are uniquely identified by only YANG
  Schema Item iDentifier and set of single instance nodes are the same set.

# Representing YANG 'instance-identifier' Type in CBOR

## SIDs as 'instance-identifier'

The definitions of {{Section 6.13.1 of -yang-cbor}} applies with following
exceptions:

The encoding rules for list apply only for keyed lists.

In the case of a representation node that is an entry of a keyless list, a SID
is combined with the list entry index is used to identify each instance within the
keyless list. The index MUST be encoded using CBOR unsigned integer data item
(major type 0). The index MUST be 1-base to keep same indexing base as RESTCONF
{{-restconf}} and NETCONF {{-netconf}}.

Instance-identifier of an instance that is not single instance node MUST be
encoded using a CBOR array item (major type 4) containing the following CBOR
data items:

- The first element MUST be encoded as a CBOR unsigned integer data item (major
  type 0) and set to the targeted schema node SID. No delta mechanism for SID is
  used.
- The next elements MUST contain the value of each key required to identify the
  instance of the targeted schema node. These keys MUST be ordered as defined in
  the 'key' YANG statement for keyed list. The keys are encoded according the
  rules defined in {{-yang-cbor}} and this document. If the list is keyless list
  the key MUST be encoded using the CBOR unsigned integer data item (major type 0)
  as specified in this document. The order of the keys and indices MUST be
  same as walk from top-level node down to targeted schema node.
- If the instance is leaf-list entry, the last element MUST be encoded
  according to encoding rules defined in {{-yang-cbor}} and this document.

This means that instance-identifier identifing a leaf-list instance with single
instance node parent will result in a CBOR array with two elements, the SID as
CBOR unsigned integer and leaf-list value representation.

Instance-identifier of a list or leaf-list schema node is encoded in the same way as a list or leaf-list
entry leaving out the targeted schema node identification. This identification is all the keys of keyed list,
integer index of keyless list and instance of leaf-list. If the instance identifier would result in CBOR array data item
having only a single element -- the SID -- the instance-identifier MUST be encoded according to rules for single instance nodes.

This means that instance-identifier of list or leaf-list with single instance node parent will result
only in CBOR unsigned integer data item representing the SID.

The YANG 1.1 {{-yang}} allows leaf-list of state data (config false) to have duplicates. In
this case, it is not defined which element the instance-identifier identifies.

TODO: If these encoding rules will be accepted by the working group consensus, then changes of draft I-D.core-comi (CORECONF) need to be done.
We will get for free identification of keyless list instances that is impossible in RESTCONF.

### Examples

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

All examples are considered to live inside the `example` module namespace if
not stated otherwise. Equivalent representation using the Names encoding may
help readers already familiar with YANG JSON encoding {{-yang-json}}, or similar XML
encoding defined in YANG 1.1 {{-yang}}.

*First example:*

The following example shows the encoding of the 'reporting-entity' value
referencing 'neighbor-sysid" (which is assumed to have SID 68000) of keyless
"/isis:adjacencies/adjacency" list's second list entry. The example is adapted from
{{-isis}} and therefore uses the `isis` namespace:

~~~ yang
// in module isis
container adjacencies {
  config false;
  list adjacency {
    leaf neighbor-sysid {
      type string;
    }
    leaf more-data {
      type binary;
    }
  }
}
~~~

CBOR diagnostic notation: `[ 68000, 2 ]`

CBOR encoding:

~~~ cbor-pretty
82              # array(2)
   1A 000109A0  # 68000
   02           # 2
~~~

Equivalent instance-identifier encoded using the Names:
`"/isis:adjacencies/adjacency[.=2]/neighbor-sysid"`

*Second example:*

The following example shows the encoding of the 'reporting-entity' value
referencing leaf-list instance "/auth/foreign-user" (which is assumed to have
SID 60000) entry "alice".

CBOR diagnostic notation: `[ 60000, "alice" ]`

CBOR encoding:

~~~ cbor-pretty
82               # array(2)
   19 F6F6       # unsigned(60000)
   65            # text(5)
      616c696365 # "alice"
~~~

Equivalent instance-identifier encoded using the Names:
`"/example:auth/foreigh-user[.="alice"]"`


*Third example:*

The following example show the encoding of the 'reporting-entity' value
referencing leaf-list instance "/auth/foreign-user" (SID 60000).

CBOR diagnostic notation: `60000`

CBOR encoding: `19 F6F6`

Equivalent instance-identifier encoded using the Names: `"/example:auth/foreigh-user"`

*Fourth example:*

The following example shows the encoding of the 'reporting-entity' value
referencing leaf-list instance "/user-group/user" (which is assumed to have SID
61000) entry "eve" for group-name "restricted".

~~~ yang
list user-group {
  config true;
  key "group-name"

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
83                         # array(3)
   19 EE48                 # 61000
   6A                      # text(10)
      72657374726963746564 # "resricted"
   63                      # text(3)
      657665               # "eve"
~~~

Equivalent instance-identifier encoded using the Names:
`"/example:user-group[group-name="restricted"]/user[.="eve"]"`


*Fifth example:*

The following example shows the encoding of 'reporting-entity' value
referencing leaf-list instance "/user-group/user" for group name "restricted".

CBOR diagnostic notation: `[ 61000, "restricted" ]`

CBOR encoding:

~~~ cbor-pretty
83                         # array(3)
   19 EE48                 # 61000
   6A                      # text(10)
      72657374726963746564 # "resricted"
~~~

Equivalent instance-identifier encoded using the Names:
`"/example:user-group[group-name="restricted"]"`

Note that this encoding is same as if the node user was a leaf.

*Sixth example:*

The following example shows the encoding of 'reporting-entity' value
referencing leaf-list instance "/working-group/chair" entry. This entry
references "/auth/foreign-user" leaf-list entry "John Smith". The
"/working-group/chair" is assumed to have SID 62000.

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
83                            # array(3)
   19 F230                    # 62000
   64                         # text(4)
      636F7265                # "core"
   82                         # array(2)
      19 F6F6                 # 60000
      6A                      # text(10)
         4a6f686e20536d697468 # "John Smith"
~~~

Equivalent instance-identifier encoded using the Names:
`"/example:working-group[name="core"]/chair=[.="/example:auth/foreign-user[.="John Smith"]"]`

TODO longer chains of leaf-list instance-identifier lead to high nesting of the CBOR array data items. Shoul a cap for the contrained nodes by put to simplify the implementations?
I think cap around 8 should be suffient for most deployments. I think that using leaf-list instance-identifier chaining is not a good practise.

*Seventh example:*

The following exampke shows the encoding of 'reporting-entity' value
referencing leaf 'token-data' of device with 'id' "id01", first 'security' list
entry for user's 'bob' second 'access-token' list entry. The leaf 'token-data'
is assumed to have SID 61500.

~~~ yang
list device {
  key "id";

  leaf id {
    type string;
  }

  list security {
    config false;

    list user {
      key "name";
      leaf name;

      list access-token {
        leaf type {
          type identityref { base token; }
        }
        leaf token-data {
          type binary;
        }
      }
    }
  }
}

identity token;
~~~

CBOR diagnostic notation: `[ 61500, "id01", 1, "bob", 2 ]`

CBOR encoding:

~~~ cbor-pretty
84             # array(4)
   19 F03C     # 61500
   64          # text(4)
      69643031 # "id01"
   01          # 1
   63          # text(3)
      626F62   # "bob"
   02          # 2
~~~

Equivalent instance-identifier encoded using the Names:
`"/example:device[id="id01"]/security[.=1]/user[user="bob"]/access-token[.=2]/token-data"`

# Content-Types
TODO Is it possible to reuse the Content-types define in the {{-yang-cbor}}? It would be wasteful to assign new MIME content-type basically the same format.

# Security Considerations
The security considerations of {{-cbor}}, {{-yang}}, {{-yang-cbor}} and
{{-yang-sid}} apply.

The implementations should be aware of possibly very large recursive nesting that occurs when instance-identifiers are chained.

TODO Security


# IANA Considerations
This document has no IANA actions.

TODO Is it possible to keep the same IANA allocations of th {{-yang-cbor}}? This draft wants to be more of a bugfix document than new encoding scheme.


--- back

# Acknowledgments
{:numbered="false"}

TODO acknowledge. thank Andy Bierman for his friendly responses on mailing list.
