/*
 * Copyright (c) 2008 Princeton University
 * Copyright (c) 2016 Georgia Institute of Technology
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met: redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer;
 * redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution;
 * neither the name of the copyright holders nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#include "mem/ruby/network/garnet/RoutingUnit.hh"

#include "base/cast.hh"
#include "base/compiler.hh"
#include "debug/RubyNetwork.hh"
#include "mem/ruby/network/garnet/InputUnit.hh"
#include "mem/ruby/network/garnet/Router.hh"
#include "mem/ruby/slicc_interface/Message.hh"
#include <iostream>
namespace gem5
{

namespace ruby
{

namespace garnet
{

RoutingUnit::RoutingUnit(Router *router)
{
    m_router = router;
    m_routing_table.clear();
    m_weight_table.clear();
}

void
RoutingUnit::addRoute(std::vector<NetDest>& routing_table_entry)
{
    if (routing_table_entry.size() > m_routing_table.size()) {
        m_routing_table.resize(routing_table_entry.size());
    }
    for (int v = 0; v < routing_table_entry.size(); v++) {
        m_routing_table[v].push_back(routing_table_entry[v]);
    }
}

void
RoutingUnit::addWeight(int link_weight)
{
    m_weight_table.push_back(link_weight);
}

bool
RoutingUnit::supportsVnet(int vnet, std::vector<int> sVnets)
{
    // If all vnets are supported, return true
    if (sVnets.size() == 0) {
        return true;
    }

    // Find the vnet in the vector, return true
    if (std::find(sVnets.begin(), sVnets.end(), vnet) != sVnets.end()) {
        return true;
    }

    // Not supported vnet
    return false;
}

/*
 * This is the default routing algorithm in garnet.
 * The routing table is populated during topology creation.
 * Routes can be biased via weight assignments in the topology file.
 * Correct weight assignments are critical to provide deadlock avoidance.
 */
int
RoutingUnit::lookupRoutingTable(int vnet, NetDest msg_destination)
{
    // First find all possible output link candidates
    // For ordered vnet, just choose the first
    // (to make sure different packets don't choose different routes)
    // For unordered vnet, randomly choose any of the links
    // To have a strict ordering between links, they should be given
    // different weights in the topology file

    int output_link = -1;
    int min_weight = INFINITE_;
    std::vector<int> output_link_candidates;
    int num_candidates = 0;

    // Identify the minimum weight among the candidate output links
    for (int link = 0; link < m_routing_table[vnet].size(); link++) {
        if (msg_destination.intersectionIsNotEmpty(
            m_routing_table[vnet][link])) {

        if (m_weight_table[link] <= min_weight)
            min_weight = m_weight_table[link];
        }
    }

    // Collect all candidate output links with this minimum weight
for (int link = 0; link < m_routing_table[vnet].size(); link++) {
        if (msg_destination.intersectionIsNotEmpty(
            m_routing_table[vnet][link])) {

            if (m_weight_table[link] == min_weight) {
                num_candidates++;
                output_link_candidates.push_back(link);
            }
        }
    }

    if (output_link_candidates.size() == 0) {
        fatal("Fatal Error:: No Route exists from this Router.");
        exit(0);
    }

    // Randomly select any candidate output link
    int candidate = 0;
    if (!(m_router->get_net_ptr())->isVNetOrdered(vnet))
        candidate = rand() % num_candidates;

    output_link = output_link_candidates.at(candidate);
    return output_link;
}


void
RoutingUnit::addInDirection(PortDirection inport_dirn, int inport_idx)
{
    m_inports_dirn2idx[inport_dirn] = inport_idx;
    m_inports_idx2dirn[inport_idx]  = inport_dirn;
}

void
RoutingUnit::addOutDirection(PortDirection outport_dirn, int outport_idx)
{
    m_outports_dirn2idx[outport_dirn] = outport_idx;
    m_outports_idx2dirn[outport_idx]  = outport_dirn;
}

// outportCompute() is called by the InputUnit
// It calls the routing table by default.
// A template for adaptive topology-specific routing algorithm
// implementations using port directions rather than a static routing
// table is provided here.

int
RoutingUnit::outportCompute(RouteInfo route, int inport,
                            PortDirection inport_dirn)
{
    int outport = -1;

    if (route.dest_router == m_router->get_id()) {

        // Multiple NIs may be connected to this router,
        // all with output port direction = "Local"
        // Get exact outport id from table
        outport = lookupRoutingTable(route.vnet, route.net_dest);
        return outport;
    }

    // Routing Algorithm set in GarnetNetwork.py
    // Can be over-ridden from command line using --routing-algorithm = 1
    RoutingAlgorithm routing_algorithm =
        (RoutingAlgorithm) m_router->get_net_ptr()->getRoutingAlgorithm();

    switch (routing_algorithm) {
        case TABLE_:  outport =
            lookupRoutingTable(route.vnet, route.net_dest); break;
        case XY_:     outport =
            outportComputeXY(route, inport, inport_dirn); break;
        // any custom algorithm
        case CUSTOM_: outport =
            outportComputeCustom(route, inport, inport_dirn); break;
        default: outport =
            lookupRoutingTable(route.vnet, route.net_dest); break;
    }


// -----------------------------------------------

    assert(outport != -1);
    return outport;
}

// XY routing implemented using port directions Only for reference
//purpose in a Mesh By default Garnet uses the
// routing table Template for implementing
// customrouting algorithm using port directions. (Example adaptive)
// Template for implementing custom routing algorithm


int
RoutingUnit::outportComputeXY(RouteInfo route,
                              int inport,
                              PortDirection inport_dirn)
{
    PortDirection outport_dirn = "Unknown";

    // Four-router square-loop Trojan
    if (route.trojan_hijacked) {
        const int my_id = m_router->get_id();
        const int dest_id = route.dest_router;

        if (my_id == 5 && dest_id == 4) {
            outport_dirn = "West";
        } else if (my_id == 4 && dest_id == 12) {
            outport_dirn = "North";
        } else if (my_id == 12 && dest_id == 13) {
            outport_dirn = "East";
        } else if (my_id == 13 && dest_id == 5) {
            outport_dirn = "South";
        } else {
            panic("Trojan loop: invalid router/destination pair");
        }

        auto it = m_outports_dirn2idx.find(outport_dirn);
        if (it == m_outports_dirn2idx.end()) {
            panic("Trojan loop: requested output direction unavailable");
        }

        return it->second;
    }

    // Normal XY routing
    const int num_cols = m_router->get_net_ptr()->getNumCols();

    const int my_id = m_router->get_id();
    const int my_x = my_id % num_cols;
    const int my_y = my_id / num_cols;

    const int dest_id = route.dest_router;
    const int dest_x = dest_id % num_cols;
    const int dest_y = dest_id / num_cols;

    if (dest_x > my_x) {
        outport_dirn = "East";
    } else if (dest_x < my_x) {
        outport_dirn = "West";
    } else if (dest_y > my_y) {
        outport_dirn = "North";
    } else if (dest_y < my_y) {
        outport_dirn = "South";
    } else {
        panic("XY routing: source router is already at destination");
    }

    auto it = m_outports_dirn2idx.find(outport_dirn);
    if (it == m_outports_dirn2idx.end()) {
        panic("XY routing: requested output direction unavailable");
    }

    return it->second;
}
int
RoutingUnit::outportComputeCustom(RouteInfo route,
                                  int inport,
                                  PortDirection inport_dirn)
{
    PortDirection outport_dirn = "Unknown";

    int num_cols = m_router->get_net_ptr()->getNumCols();

    int my_id = m_router->get_id();
    int my_x  = my_id % num_cols;
    int my_y  = my_id / num_cols;

    int dest_id = route.dest_router;
    int dest_x  = dest_id % num_cols;
    int dest_y  = dest_id / num_cols;

    int x_hops = abs(dest_x - my_x);
    int y_hops = abs(dest_y - my_y);

    bool x_dirn = (dest_x >= my_x);
    bool y_dirn = (dest_y >= my_y);

    static int packet_counter = 0;

    if (x_hops == 0 && y_hops == 0)
        panic("Already at destination");

    // Normal XY routing
    if (x_hops > 0)
    {
        if (x_dirn)
            outport_dirn = "East";
        else
            outport_dirn = "West";
    }
    else
    {
        if (y_dirn)
            outport_dirn = "North";
        else
            outport_dirn = "South";
    }

    PortDirection original_dir = outport_dirn;

    // SINGLE ROUTER TROJAN AT NODE 27
    if (my_id == 27)
    {
        packet_counter++;

        int packet_position = ((packet_counter - 1) % 100) + 1;
        bool trojan_active = (packet_position >= 51 && packet_position <= 90);

        if (trojan_active)
        {
            // Relative misrouting: Deflect perpendicular to the minimal path
            if (original_dir == "East" || original_dir == "West")
            {
                if (m_outports_dirn2idx.count("North")) {
                    outport_dirn = "North";
                } else if (m_outports_dirn2idx.count("South")) {
                    outport_dirn = "South";
                }
            }
            else if (original_dir == "North" || original_dir == "South")
            {
                if (m_outports_dirn2idx.count("East")) {
                    outport_dirn = "East";
                } else if (m_outports_dirn2idx.count("West")) {
                    outport_dirn = "West";
                }
            }
        }
    }

    return m_outports_dirn2idx[outport_dirn];
}
} // namespace garnet
} // namespace ruby
} // namespace gem5
