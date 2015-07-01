/** \file ami_rx.cpp
 *  \brief Implementation of AmiRx class.
 *
 * Original author: David Banas <br>
 * Original date:   May 20, 2015
 *
 * Copyright (c) 2015 David Banas; all rights reserved World wide.
 */

#include <string>
#include <vector>
#include <algorithm>
#include <memory>
#include "include/ami_rx.h"
#include "include/util.h"

#define MAX_INIT_ADAPT_BITS 10000

extern std::ostringstream debug_stream;

/// Initializer
void AmiRx::init(double *impulse_matrix, const long number_of_rows,
                 const long aggressors, const double sample_interval,
                 const double bit_time, const std::string& AMI_parameters_in) {
    // Let our base class do its thing.
    inherited::init(impulse_matrix, number_of_rows, aggressors, sample_interval, bit_time, AMI_parameters_in);

    // Initialize our own state.
    delete ctle_;
    delete dfe_;
    ctle_ = nullptr;
    dfe_ = nullptr;
    dump_dfe_adaptation_ = 0;
    dump_adaptation_input_ = 0;
    sig_tap_ = 0;
    init_adapt_tap_ = 0;

    // Grab debugging related parameters and configure things accordingly.
    std::vector<std::string> node_names; node_names.clear();
    node_names.push_back("debug");
    node_names.push_back("enable");
    int dbg_enable = get_param_int(node_names, 0);
    node_names.pop_back();
    node_names.push_back("sig_tap");
    int sig_tap = get_param_int(node_names, 0);
    node_names.pop_back();
    node_names.push_back("init_adapt_tap");
    int init_adapt_tap = get_param_int(node_names, 0);
    node_names.pop_back();
    node_names.pop_back();
    if (dbg_enable) {
        sig_tap_ = sig_tap;
        init_adapt_tap_ = init_adapt_tap;
    }
    std::ostringstream msg_stream;
    msg_stream << "Debugging parameters:\n";
    msg_stream << "\tenable: " << dbg_enable << "\n";
    msg_stream << "\tsig_tap: " << sig_tap << "\n";
    msg_stream << "\tinit_adapt_tap: " << init_adapt_tap << "\n";
    msg_ += msg_stream.str();
}

/// Override of AMIModel::proc_sig() specific to Rx models.
bool AmiRx::proc_sig(double *sig, long len, double *clock_times) {
    if (ctle_) {
        ctle_->apply(sig, len);
    }
    if (dfe_) {
        return dfe_->apply(sig, len, clock_times);
    } else {
        return true;
    }
}

/// Override of AMIModel::proc_imp() specific to Rx models.
void AmiRx::proc_imp() {
    std::ostringstream params;
    params.flush();
    params << "(example_rx ";

    if (sig_tap_ == 1) // Return input unmodified.
        return;

    // Apply our filter.
    if (ctle_)
        ctle_->apply(impulse_matrix_, number_of_rows_);
    if (sig_tap_ == 2) // Return post-CTLE signal.
        return;
    if (dfe_) {
        unsigned long offset = 0;
        double max_imp = 0.0;
        for (unsigned long i = 0; i < number_of_rows_; i++)
            if (impulse_matrix_[i] > max_imp) {
                offset = i;
                max_imp = impulse_matrix_[i];
            }
        int tap_num = 1;
        for (auto weight : dfe_->get_weights()) {
            offset += samples_per_bit_;
            double sum = 0;
            for (unsigned long j = 0; j < offset; j++)
                sum += impulse_matrix_[j];
            sum *= sample_interval_;
            if (dfe_->mode > 1) {  // Emulate adaptation.
                impulse_matrix_[offset] = -(sum - dfe_->slicer_mag()) / sample_interval_;
                weight = -impulse_matrix_[offset] * sum / dfe_->slicer_mag() * sample_interval_;
                params << " (dfe_tap" << tap_num++ << " " << weight << ")";
            } else {
                impulse_matrix_[offset] = -(weight * dfe_->slicer_mag() / sum) / sample_interval_;
            }
        }
    }

    params << ")\n";
    param_str_ = params.str();

    msg_ += debug_stream.str();
}

