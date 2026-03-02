---
v: 3

docname: draft-vilimek-yang-cbor-inst-id-latest
title: "Encoding rules of YANG instance-identifier in the Concise Binary Object Representation (CBOR)"
abbrev: "yang-cbor-inst-id"
updates: RFC9254

stream: IETF
category: std
consensus: true

number:
date:
area: AREA
wg: CoRE
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

The YANG-CBOR document {{-yang-cbor}} defines rules for representing
YANG-modeled data {{-yang}} in CBOR {{-cbor}}. The YANG-CBOR defines rules for all
built-in types, such as int64, leafref, and instance-identifier data type. However it fails to address
some cases of the instance-identifier, specifically those pointing
to keyless list entries or leaf-list entries. This documents updates {{-yang-cbor}} to make the rules complete.

--- middle

# Introduction

The {{-yang-cbor}}: Encoding Rules of Data Modeled with YANG in the Concise Binary
Object Representation (CBOR) defines rules for representing of YANG-modeled data {{-yang}}
in CBOR {{-cbor}}. The instance-identifier YANG data type is well-defined for instances that
reference containers, lists with one or more keys, and leafs. The document fails to address cases
when the instance-identifier instance points to entries in a list with no keys or a leaf-list.
The YANG-CBOR refines encoding rules of two kinds. One variant, named as using names, is compatible with YANG-JSON {{-yang-json}}
encoding. The second variant uses SIDs to compress the information needed to encode the instance-identifier.
Only the SID-based encoding rules are incomplete.
This documents aims to define the missing rules and to clarify the terminology used.


# Terminology and Notation

{::boilerplate bcp14-tagged}

The following terms are defined in {{-yang}}:

- list
- leaf-list
- leaf
- container
- instance-identifier

The following term is defined in {{-cbor}}:

- data item

The following terms are defined in {{-yang-cbor}}:

- YANG Scheme Item iDentifier (YANG SID, or simply SID)
- delta (of YANG SIDs)
- absolute SID

The following terms are defined in {{-yang-sid}}:

- item

Keyless list:
: Is config false YANG list without any keys.

Keyed list:
: Is YANG list that is not a keyless list. It is either a config true list or
  a config false list with at least one key. Note that a config true list must have at least one key.

# Representing SIDs as YANG instance-identifier in CBOR

## Motivation example {#motivation}

Definition example adapted from {{-yang}}:

~~~ yang
container system {
  ...
  leaf reporting-entity {
    type instance-identifier;
  }
}
~~~

The following example shows the encoding of the 'reporting-entity' value
referencing "neighbor-sysid" (which is assumed to have SID 68000) of the second list entry of the keyless
"/isis:adjacencies/adjacency" list. The example is adapted from
{{-isis}} and therefore uses the `isis` namespace:

~~~ yang
// in module isis
container adjacencies {
  config false;
  list adjacency {
    leaf neighbor-sysid {  // SID 68000
      type string;
    }
    leaf more-data {
      type binary;
    }
  }
}
~~~

We want to represent `reporting-entity` so that the value is
`"/isis:adjacencies/adjacency[.=2]/neighbor-sysid"`, but we want to use SIDs.
Becuase the YANG list does not specify any keys, we will use index-based identification.

CBOR diagnostic notation: `[ 68000, 2 ]`

CBOR encoding:

~~~ cbor-pretty
82              # array(2)
   1A 000109A0  # 68000
   02           # 2
~~~

Where `68000` is absolute SID and `2` is 1-based index of the list entry.

## Rules

The definitions of {{Section 6.13.1 of -yang-cbor}} require that the list entries are
encoded as CBOR array with SID as the first element, followed by keys in same order as walking from
the schema root to the targeted child node. This formulation only applies to keyed lists.

For keyless lists, the entry identification MUST be encoded using a CBOR unsigned integer data item
(major type 0). The index MUST be 1-based to maintain the same indexing base as RESTCONF {{-restconf}}
and NETCONF {{-netconf}}.

If the target data node is a leaf-list entry, the last element of the CBOR array MUST
be encoded according to the encoding rules for the given leaf-list's type.

The YANG 1.1 {{-yang}} allows a leaf-list of state data (config false) to have duplicates. In
this case, it is not defined which element the instance-identifier identifies.

Due to restrictions set forth in {{Section 9.13 of -yang}} it is not possible to point the instance-identifier to a list or a leaf-list schema node.
Only instance data (i.e. nodes in the data tree) can be targeted.

TODO: If these encoding rules are accepted by the working group consensus, changes to the draft I-D.core-comi (CORECONF) will be necessary.
This will allow us to identify keyless list instances, which is impossible in RESTCONF.

## Examples

Unless stated otherwise, all examples are considered to live inside the `example` module namespace.
An equivalent representation using the Names encoding may
help readers who are already familiar with YANG JSON encoding {{-yang-json}}, or similar XML
encoding defined in YANG 1.1 {{-yang}}.

### Simple leaf-list instance-identifier

The following example shows the encoding of the 'reporting-entity' value
referencing leaf-list instance "/auth/foreign-user" (which is assumed to have
SID 60000) entry "alice". The name-based representation is
`"/example:auth/foreigh-user[.="alice"]"`.

~~~ yang
container auth {
  leaf-list foreign-user { // SID 60000
    type string;
  }
}
~~~

CBOR diagnostic notation: `[ 60000, "alice" ]`

CBOR encoding:

~~~ cbor-pretty
82               # array(2)
   19 F6F6       # unsigned(60000)
   65            # text(5)
      616c696365 # "alice"
~~~

### Leaf-list inside list {#leaf-list-inst}

The following example shows the encoding of the 'reporting-entity' value
referencing leaf-list instance "/user-group/user" (which is assumed to have SID
61000) entry "eve" for group-name "restricted". The name-based representation is
`"/example:user-group[group-name="restricted"]/user[.="eve"]"`.

~~~ yang
list user-group {
  config true;
  key "group-name"

  leaf group-name {
    type string;
  }

  leaf-list user { // SID 61000
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


### List instance

We reuse the YANG snippet from {{leaf-list-inst}}.
The following example shows the encoding of 'reporting-entity' value
referencing list instance "/user-group" for group name "restricted".
The name-based representation is
`"/example:user-group[group-name="restricted"]"`.

CBOR diagnostic notation: `[ 61000, "restricted" ]`

CBOR encoding:

~~~ cbor-pretty
83                         # array(3)
   19 EE48                 # 61000
   6A                      # text(10)
      72657374726963746564 # "resricted"
~~~

### Instance-identifier chaining

The following example shows the encoding of 'reporting-entity' value
referencing leaf-list instance "/working-group/chair" entry. This entry
references "/auth/foreign-user" leaf-list entry "Carsten Bormann". The
"/working-group/chair" is assumed to have SID 62000. The name-based representation is
`"/example:working-group[name="core"]/chair=[.="/example:auth/foreign-user[.="John Smith"]"]`.

~~~ yang
list working-group {
  leaf name {
    type string;
  }

  leaf-list chair { // SID 62000
    type instance-identifier;
  }
}
~~~

CBOR diagnostic notation: `[ 62000, "core", [ 60000, "Carsten Bormann" ] ]`

CBOR encoding:

~~~ cbor-pretty
83                                        # array(3)
   19 F230                                # 62000
   64                                     # text(4)
      636F7265                            # "core"
   82                                     # array(2)
      19 F6F6                             # 60000
      6F                                  # text(15)
         4361727374656E20426F726D616E6E   # "Carsten Bormann"

~~~


TODO longer chains of leaf-list instance-identifier lead to high nesting of the CBOR array data items. Shoul a cap for the contrained nodes by put to simplify the implementations?
I think cap around 8 should be suffient for most deployments. I think that using leaf-list instance-identifier chaining is not a good practise.

### Complex example of mixed keyed and keyless lists

The following example shows the encoding of 'reporting-entity' value
referencing leaf 'token-data' of device with 'id' "id01", first 'security' list
entry for user's 'bob' second 'access-token' list entry. The leaf 'token-data'
is assumed to have SID 61500.
The name-based representation is
`"/example:device[id="id01"]/security[.=1]/user[user="bob"]/access-token[.=2]/token-data"`.

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
        leaf token-data { // SID 61500
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

# Content-Types
TODO Is it possible to reuse the Content-types define in the {{-yang-cbor}}? It would be wasteful to assign new MIME content-type to basically the same format.

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
