[1mdiff --cc src/libslic3r/GCode.cpp[m
[1mindex e3bb13a75c,19909b2bcf..0000000000[m
[1m--- a/src/libslic3r/GCode.cpp[m
[1m+++ b/src/libslic3r/GCode.cpp[m
[36m@@@ -4447,24 -1978,12 +4447,28 @@@[m [mLayerResult GCode::process_layer[m
      gcode += this->change_layer(print_z);  // this will increase m_layer_index[m
      m_layer = &layer;[m
      m_object_layer_over_raft = false;[m
[32m++<<<<<<< HEAD[m
[32m +[m
[32m +    if (!m_config.time_lapse_gcode.value.empty() && !is_BBL_Printer()) {[m
[32m++=======[m
[32m+     if (! print.config().layer_gcode.value.empty()) {[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
          DynamicConfig config;[m
          config.set_key_value("layer_num", new ConfigOptionInt(m_layer_index));[m
[32m +        config.set_key_value("layer_z", new ConfigOptionFloat(print_z));[m
[32m +        config.set_key_value("max_layer_z", new ConfigOptionFloat(m_max_layer_z));[m
[32m +        gcode += this->placeholder_parser_process("timelapse_gcode",[m
[32m +             print.config().time_lapse_gcode.value, m_writer.filament()->id(), &config)[m
[32m +             + "\n";[m
[32m +    }[m
[32m +[m
[32m +    if (!m_config.layer_change_gcode.value.empty()) {[m
[32m +        DynamicConfig config;[m
[32m +        config.set_key_value("most_used_physical_extruder_id", new ConfigOptionInt(m_config.physical_extruder_map.get_at(most_used_extruder)));[m
[32m +        config.set_key_value("layer_num", new ConfigOptionInt(m_layer_index));[m
          config.set_key_value("layer_z",   new ConfigOptionFloat(print_z));[m
[31m -        gcode += this->placeholder_parser_process("layer_gcode",[m
[31m -            print.config().layer_gcode.value, m_writer.extruder()->id(), &config)[m
[32m +        gcode += this->placeholder_parser_process("layer_change_gcode",[m
[32m +            print.config().layer_change_gcode.value, m_writer.filament()->id(), &config)[m
              + "\n";[m
          config.set_key_value("max_layer_z", new ConfigOptionFloat(m_max_layer_z));[m
      }[m
[36m@@@ -5137,82 -2235,18 +5141,93 @@@[m
              if (is_anything_overridden && print_wipe_extrusions == 0)[m
                  gcode+="; PURGING FINISHED\n";[m
  [m
[32m +            bool skirt_generated_for_current_print_z = false;[m
[32m +[m
              for (InstanceToPrint &instance_to_print : instances_to_print) {[m
[32m++<<<<<<< HEAD[m
[32m +                if (print.config().skirt_type == stPerObject && [m
[32m +                    !instance_to_print.print_object.object_skirt().empty() &&[m
[32m +                    print.config().print_sequence == PrintSequence::ByLayer)[m
[32m +                {[m
[32m +                    const LayerToPrint& layer_to_print = layers[instance_to_print.layer_id];[m
[32m +                    const Layer* skirt_layer = layer_to_print.object_layer;[m
[32m +                    if (skirt_layer == nullptr && layer_to_print.support_layer != nullptr &&[m
[32m +                        layer_to_print.support_layer->id() < layer_to_print.support_layer->object()->slicing_parameters().raft_layers()) {[m
[32m +                        skirt_layer = layer_to_print.support_layer;[m
[32m +                    }[m
[32m +[m
[32m +                    if (skirt_layer != nullptr &&[m
[32m +                        (skirt_layer->id() < print.config().skirt_height || print.config().draft_shield == DraftShield::dsEnabled)) {[m
[32m +                        const bool skirt_first_layer = (skirt_layer->id() == 0 && std::abs(skirt_layer->bottom_z()) < EPSILON);[m
[32m +                        if (skirt_first_layer)[m
[32m +                            m_skirt_done.clear();[m
[32m +[m
[32m +                        if (skirt_generated_for_current_print_z && !m_skirt_done.empty())[m
[32m +                            m_skirt_done.pop_back();[m
[32m +[m
[32m +                        const Point& offset      = instance_to_print.print_object.instances()[instance_to_print.instance_id].shift;[m
[32m +                        std::string  skirt_gcode = generate_skirt(print, instance_to_print.print_object.object_skirt(), offset,[m
[32m +                                                                  instance_to_print.print_object.config().skirt_start_angle, layer_tools,[m
[32m +                                                                  *skirt_layer, extruder_id);[m
[32m +                        if (!skirt_gcode.empty())[m
[32m +                            skirt_generated_for_current_print_z = true;[m
[32m +                        gcode += std::move(skirt_gcode);[m
[32m +                    }[m
[32m +                }[m
[32m +                [m
[32m +                const auto& inst = instance_to_print.print_object.instances()[instance_to_print.instance_id];[m
[32m +                const LayerToPrint &layer_to_print = layers[instance_to_print.layer_id];[m
[32m +                // To control print speed of the 1st object layer printed over raft interface.[m
[32m +                bool object_layer_over_raft = layer_to_print.object_layer && layer_to_print.object_layer->id() > 0 &&[m
[32m +                    instance_to_print.print_object.slicing_parameters().raft_layers() == layer_to_print.object_layer->id();[m
[32m +                m_config.apply(print.default_region_config());[m
[32m +                m_config.apply(instance_to_print.print_object.config(), true);[m
[32m +                m_layer = layer_to_print.layer();[m
[32m +                m_object_layer_over_raft = object_layer_over_raft;[m
[32m +                if (m_config.reduce_crossing_wall)[m
[32m++=======[m
[32m+                 const LayerToPrint &layer_to_print = layers[instance_to_print.layer_id];[m
[32m+                 // To control print speed of the 1st object layer printed over raft interface.[m
[32m+                 bool object_layer_over_raft = layer_to_print.object_layer && layer_to_print.object_layer->id() > 0 && [m
[32m+                     instance_to_print.print_object.slicing_parameters().raft_layers() == layer_to_print.object_layer->id();[m
[32m+                 m_config.apply(instance_to_print.print_object.config(), true);[m
[32m+                 m_layer = layer_to_print.layer();[m
[32m+                 m_object_layer_over_raft = object_layer_over_raft;[m
[32m+                 if (m_config.avoid_crossing_perimeters)[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
                      m_avoid_crossing_perimeters.init_layer(*m_layer);[m
[31m -                if (this->config().gcode_label_objects)[m
[31m -                    gcode += std::string("; printing object ") + instance_to_print.print_object.model_object()->name + " id:" + std::to_string(instance_to_print.layer_id) + " copy " + std::to_string(instance_to_print.instance_id) + "\n";[m
[32m +[m
[32m +                if (this->config().gcode_label_objects) {[m
[32m +                    gcode += std::string("; printing object ") + instance_to_print.print_object.model_object()->name +[m
[32m +                             " id:" + std::to_string(instance_to_print.print_object.get_id()) + " copy " +[m
[32m +                             std::to_string(inst.id) + "\n";[m
[32m +                }[m
[32m +                // exclude objects[m
[32m +                if (m_enable_exclude_object) {[m
[32m +                    if (is_BBL_Printer()) {[m
[32m +                        m_writer.set_object_start_str([m
[32m +                            std::string("; start printing object, unique label id: ") +[m
[32m +                            std::to_string(instance_to_print.label_object_id) + "\n" + "M624 " +[m
[32m +                            _encode_label_ids_to_base64({instance_to_print.label_object_id}) + "\n");[m
[32m +                    } else {[m
[32m +                        const auto gflavor = print.config().gcode_flavor.value;[m
[32m +                        if (gflavor == gcfKlipper) {[m
[32m +                            m_writer.set_object_start_str(std::string("EXCLUDE_OBJECT_START NAME=") +[m
[32m +                                                          get_instance_name(&instance_to_print.print_object, inst.id) + "\n");[m
[32m +                        }[m
[32m +                        else if (gflavor == gcfMarlinLegacy || gflavor == gcfMarlinFirmware || gflavor == gcfRepRapFirmware) {[m
[32m +                            std::string str = std::string("M486 S") + std::to_string(inst.unique_id) + "\n";[m
[32m +                            m_writer.set_object_start_str(str);[m
[32m +                        }[m
[32m +                    }[m
[32m +                }[m
[32m +[m
[32m +                // Orca(#7946): set current obj regardless of the `enable_overhang_speed` value, because[m
[32m +                // `enable_overhang_speed` is a PrintRegionConfig and here we don't have a region yet.[m
[32m +                // And no side effect doing this even if `enable_overhang_speed` is off, so don't bother[m
[32m +                // checking anything here.[m
[32m +                m_extrusion_quality_estimator.set_current_object(&instance_to_print.print_object);[m
[32m +[m
                  // When starting a new object, use the external motion planner for the first travel move.[m
                  const Point &offset = instance_to_print.print_object.instances()[instance_to_print.instance_id].shift;[m
                  std::pair<const PrintObject*, Point> this_object_copy(&instance_to_print.print_object, offset);[m
[36m@@@ -5220,49 -2254,12 +5235,58 @@@[m
                      m_avoid_crossing_perimeters.use_external_mp_once();[m
                  m_last_obj_copy = this_object_copy;[m
                  this->set_origin(unscale(offset));[m
[32m++<<<<<<< HEAD[m
[32m +                if (instance_to_print.object_by_extruder.support != nullptr) {[m
[32m +                    m_layer = layers[instance_to_print.layer_id].support_layer;[m
[32m +                    m_object_layer_over_raft = false;[m
[32m +[m
[32m +                    //BBS: print supports' brims first[m
[32m +                    if (this->m_objSupportsWithBrim.find(instance_to_print.print_object.id()) != this->m_objSupportsWithBrim.end() && !print_wipe_extrusions) {[m
[32m +                        this->set_origin(0., 0.);[m
[32m +                        m_avoid_crossing_perimeters.use_external_mp();[m
[32m +                        for (const ExtrusionEntity* ee : print.m_supportBrimMap.at(instance_to_print.print_object.id()).entities) {[m
[32m +                            gcode += this->extrude_entity(*ee, "brim", m_config.support_speed.value);[m
[32m +                        }[m
[32m +                        m_avoid_crossing_perimeters.use_external_mp(false);[m
[32m +                        // Allow a straight travel move to the first object point.[m
[32m +                        m_avoid_crossing_perimeters.disable_once();[m
[32m +                        this->m_objSupportsWithBrim.erase(instance_to_print.print_object.id());[m
[32m +                    }[m
[32m +                    // When starting a new object, use the external motion planner for the first travel move.[m
[32m +                    const Point& offset = instance_to_print.print_object.instances()[instance_to_print.instance_id].shift;[m
[32m +                    std::pair<const PrintObject*, Point> this_object_copy(&instance_to_print.print_object, offset);[m
[32m +                    if (m_last_obj_copy != this_object_copy)[m
[32m +                        m_avoid_crossing_perimeters.use_external_mp_once();[m
[32m +                    m_last_obj_copy = this_object_copy;[m
[32m +                    this->set_origin(unscale(offset));[m
[32m +                    ExtrusionEntityCollection support_eec;[m
[32m +[m
[32m +                    // BBS[m
[32m +                    WipingExtrusions& wiping_extrusions = const_cast<LayerTools&>(layer_tools).wiping_extrusions();[m
[32m +                    bool support_overridden = wiping_extrusions.is_support_overridden(layer_to_print.original_object);[m
[32m +                    bool support_intf_overridden = wiping_extrusions.is_support_interface_overridden(layer_to_print.original_object);[m
[32m +[m
[32m +                    ExtrusionRole support_extrusion_role = instance_to_print.object_by_extruder.support_extrusion_role;[m
[32m +                    bool is_overridden = support_extrusion_role == erSupportMaterialInterface ? support_intf_overridden : support_overridden;[m
[32m +                    if (is_overridden == (print_wipe_extrusions != 0)) {[m
[32m +                        gcode += this->extrude_support([m
[32m +                            // support_extrusion_role is erSupportMaterial, erSupportTransition, erSupportMaterialInterface or erMixed for all extrusion paths.[m
[32m +                            *instance_to_print.object_by_extruder.support, support_extrusion_role);[m
[32m +[m
[32m +                        // Make sure ironing is the last[m
[32m +                        if (support_extrusion_role == erMixed || support_extrusion_role == erSupportMaterialInterface) {[m
[32m +                            gcode += this->extrude_support(*instance_to_print.object_by_extruder.support, erIroning);[m
[32m +                        }[m
[32m +                    }[m
[32m +[m
[32m++=======[m
[32m+                 if (instance_to_print.object_by_extruder.support != nullptr && !print_wipe_extrusions) {[m
[32m+                     m_layer = layer_to_print.support_layer;[m
[32m+                     m_object_layer_over_raft = false;[m
[32m+                     gcode += this->extrude_support([m
[32m+                         // support_extrusion_role is erSupportMaterial, erSupportMaterialInterface or erMixed for all extrusion paths.[m
[32m+                         instance_to_print.object_by_extruder.support->chained_path_from(m_last_pos, instance_to_print.object_by_extruder.support_extrusion_role));[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
                      m_layer = layer_to_print.layer();[m
                      m_object_layer_over_raft = object_layer_over_raft;[m
                  }[m
[36m@@@ -6192,49 -2701,26 +6216,62 @@@[m [mstd::string GCode::_extrude(const Extru[m
          gcode += this->travel_to([m
              path.first_point(),[m
              path.role(),[m
[31m -            "move to first " + description + " point"[m
[32m +            "move to first " + description + " point",[m
[32m +            sloped == nullptr ? DBL_MAX : get_sloped_z(sloped->slope_begin.z_ratio)[m
          );[m
[32m +        m_need_change_layer_lift_z = false;[m
[32m +        // Orca: ensure Z matches planned layer height[m
[32m +        if (_last_pos_undefined && !slope_need_z_travel) {[m
[32m +            gcode += this->writer().travel_to_z(m_nominal_z, "ensure Z matches planned layer height", true);[m
[32m +        }[m
      }[m
  [m
[32m +[m
[32m +    // if needed, write the gcode_label_objects_end then gcode_label_objects_start[m
[32m +    // should be already done by travel_to, but just in case[m
[32m +    m_writer.add_object_change_labels(gcode);[m
[32m +[m
      // compensate retraction[m
      gcode += this->unretract();[m
[32m +    m_config.apply(m_calib_config);[m
  [m
[32m +    // Orca: optimize for Klipper, set acceleration and jerk in one command[m
[32m +    unsigned int acceleration_i = 0;[m
[32m +    double jerk = 0;[m
      // adjust acceleration[m
[31m -    {[m
[32m +    if (m_config.default_acceleration.value > 0) {[m
          double acceleration;[m
[32m++<<<<<<< HEAD[m
[32m +        if (this->on_first_layer() && m_config.initial_layer_acceleration.value > 0) {[m
[32m +            acceleration = m_config.initial_layer_acceleration.value;[m
[32m +#if 0[m
[32m +        } else if (this->object_layer_over_raft() && m_config.first_layer_acceleration_over_raft.value > 0) {[m
[32m +            acceleration = m_config.first_layer_acceleration_over_raft.value;[m
[32m +#endif[m
[32m +        } else if (m_config.get_abs_value("bridge_acceleration") > 0 && is_bridge(path.role())) {[m
[32m +            acceleration = m_config.get_abs_value("bridge_acceleration");[m
[32m +        } else if (m_config.get_abs_value("sparse_infill_acceleration") > 0 && (path.role() == erInternalInfill)) {[m
[32m +            acceleration = m_config.get_abs_value("sparse_infill_acceleration");[m
[32m +        } else if (m_config.get_abs_value("internal_solid_infill_acceleration") > 0 && (path.role() == erSolidInfill)) {[m
[32m +            acceleration = m_config.get_abs_value("internal_solid_infill_acceleration");[m
[32m +        } else if (m_config.outer_wall_acceleration.value > 0 && is_external_perimeter(path.role())) {[m
[32m +            acceleration = m_config.outer_wall_acceleration.value;[m
[32m +        } else if (m_config.inner_wall_acceleration.value > 0 && is_internal_perimeter(path.role())) {[m
[32m +            acceleration = m_config.inner_wall_acceleration.value;[m
[32m +        } else if (m_config.top_surface_acceleration.value > 0 && is_top_surface(path.role())) {[m
[32m +            acceleration = m_config.top_surface_acceleration.value;[m
[32m++=======[m
[32m+         if (this->on_first_layer() && m_config.first_layer_acceleration.value > 0) {[m
[32m+             acceleration = m_config.first_layer_acceleration.value;[m
[32m+         } else if (this->object_layer_over_raft() && m_config.first_layer_acceleration_over_raft.value > 0) {[m
[32m+             acceleration = m_config.first_layer_acceleration_over_raft.value;[m
[32m+         } else if (m_config.perimeter_acceleration.value > 0 && is_perimeter(path.role())) {[m
[32m+             acceleration = m_config.perimeter_acceleration.value;[m
[32m+         } else if (m_config.bridge_acceleration.value > 0 && is_bridge(path.role())) {[m
[32m+             acceleration = m_config.bridge_acceleration.value;[m
[32m+         } else if (m_config.infill_acceleration.value > 0 && is_infill(path.role())) {[m
[32m+             acceleration = m_config.infill_acceleration.value;[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
          } else {[m
              acceleration = m_config.default_acceleration.value;[m
          }[m
[36m@@@ -6352,211 -2755,43 +6389,226 @@@[m
              throw Slic3r::InvalidArgument("Invalid speed");[m
          }[m
      }[m
[32m++<<<<<<< HEAD[m
[32m +    //BBS: if not set the speed, then use the filament_max_volumetric_speed directly[m
[32m +    double filament_max_volumetric_speed = FILAMENT_CONFIG(filament_max_volumetric_speed);[m
[32m +    if (FILAMENT_CONFIG(filament_adaptive_volumetric_speed)){[m
[32m +        double fitted_value = calc_max_volumetric_speed(path.height, path.width, FILAMENT_CONFIG(volumetric_speed_coefficients));[m
[32m +        filament_max_volumetric_speed = std::min(filament_max_volumetric_speed, fitted_value);[m
[32m++=======[m
[32m+     if (m_volumetric_speed != 0. && speed == 0)[m
[32m+         speed = m_volumetric_speed / path.mm3_per_mm;[m
[32m+     if (this->on_first_layer())[m
[32m+         speed = m_config.get_abs_value("first_layer_speed", speed);[m
[32m+     else if (this->object_layer_over_raft())[m
[32m+         speed = m_config.get_abs_value("first_layer_speed_over_raft", speed);[m
[32m+     if (m_config.max_volumetric_speed.value > 0) {[m
[32m+         // cap speed with max_volumetric_speed anyway (even if user is not using autospeed)[m
[32m+         speed = std::min([m
[32m+             speed,[m
[32m+             m_config.max_volumetric_speed.value / path.mm3_per_mm[m
[32m+         );[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
[32m +    }[m
[32m +[m
[32m +    if (speed == 0)[m
[32m +        speed = filament_max_volumetric_speed / _mm3_per_mm;[m
[32m +    const auto _layer = layer_id();[m
[32m +    if (this->on_first_layer() || _layer - m_config.raft_layers == 0) {[m
[32m +        //BBS: for solid infill of first layer, speed can be higher as long as[m
[32m +        //wall lines have be attached[m
[32m +        if (path.role() != erBottomSurface || m_config.raft_layers > 0 && _layer - m_config.raft_layers == 0) {[m
[32m +            speed = is_perimeter(path.role()) ? m_config.get_abs_value("initial_layer_speed") :[m
[32m +                                                m_config.get_abs_value("initial_layer_infill_speed");[m
[32m +        }[m
[32m +        else if (path.role() != erBottomSurface) {[m
[32m +            speed = m_config.get_abs_value("initial_layer_speed");[m
[32m +        }[m
[32m +    }[m
[32m +    else if(m_config.slow_down_layers > 1){[m
[32m +                // Inline calculation: check if we are past the raft + first object layer, but still within the slowdown threshold[m
[32m +        if (_layer > 0 && _layer < m_config.slow_down_layers || _layer > m_config.raft_layers && (_layer == m_config.raft_layers) < m_config.slow_down_layers) {[m
[32m +            const auto first_layer_speed =[m
[32m +                is_perimeter(path.role())[m
[32m +                    ? m_config.get_abs_value("initial_layer_speed")[m
[32m +                    : m_config.get_abs_value("initial_layer_infill_speed");[m
[32m +            if (first_layer_speed < speed) {[m
[32m +                speed = std::min([m
[32m +                    speed,[m
[32m +                    Slic3r::lerp(first_layer_speed, speed,[m
[32m +                                (double) (_layer - m_config.raft_layers) / m_config.slow_down_layers));[m
[32m +            }[m
[32m +        }[m
[32m +    }[m
[32m +    // Override skirt speed if set[m
[32m +    if (path.role() == erSkirt) {[m
[32m +        const double skirt_speed = m_config.get_abs_value("skirt_speed");[m
[32m +        if (skirt_speed > 0.0)[m
[32m +        speed = skirt_speed;[m
[32m +    }[m
[32m +    //BBS: remove this config[m
[32m +    //else if (this->object_layer_over_raft())[m
[32m +    //    speed = m_config.get_abs_value("first_layer_speed_over_raft", speed);[m
[32m +    //if (m_config.max_volumetric_speed.value > 0) {[m
[32m +    //    // cap speed with max_volumetric_speed anyway (even if user is not using autospeed)[m
[32m +    //    speed = std::min([m
[32m +    //        speed,[m
[32m +    //        m_config.max_volumetric_speed.value / _mm3_per_mm[m
[32m +    //    );[m
[32m +    //}[m
[32m +    if (FILAMENT_CONFIG(filament_max_volumetric_speed) > 0) {[m
[32m +        // cap speed with max_volumetric_speed anyway (even if user is not using autospeed)[m
[32m +        speed = std::min(speed, FILAMENT_CONFIG(filament_max_volumetric_speed) / _mm3_per_mm);[m
[32m +    }[m
[32m +    // ORCA: resonance‑avoidance on short external perimeters[m
[32m +{[m
[32m +    double ref_speed = speed;  // stash the pre‑cap speed[m
[32m +    if (path.role() == erExternalPerimeter[m
[32m +        && m_config.resonance_avoidance.value) {[m
[32m +[m
[32m +        // if our original speed was above “max”, disable RA for this loop[m
[32m +        if (ref_speed > m_config.max_resonance_avoidance_speed.value) {[m
[32m +            m_resonance_avoidance = false;[m
[32m +        }[m
[32m +[m
[32m +        // re‑apply volumetric cap[m
[32m +        if (FILAMENT_CONFIG(filament_max_volumetric_speed) > 0) {[m
[32m +            speed = std::min([m
[32m +                speed,[m
[32m +                FILAMENT_CONFIG(filament_max_volumetric_speed) / _mm3_per_mm[m
[32m +            );[m
[32m +        }[m
[32m +[m
[32m +            // if still in avoidance mode and under "max", adjust speed:[m
[32m +            // - speeds in lower half of range: clamp down to "min"[m
[32m +            // - speeds in upper half of range: boost up to "max"[m
[32m +        if (m_resonance_avoidance && speed < m_config.max_resonance_avoidance_speed.value) {[m
[32m +            if (speed < m_config.min_resonance_avoidance_speed.value +[m
[32m +                            ((m_config.max_resonance_avoidance_speed.value - m_config.min_resonance_avoidance_speed.value) / 2)) {[m
[32m +                speed = std::min(speed, m_config.min_resonance_avoidance_speed.value);[m
[32m +            } else {[m
[32m +                speed = m_config.max_resonance_avoidance_speed.value;[m
[32m +            }[m
[32m +        }[m
[32m +[m
[32m +        // reset flag for next segment[m
[32m +        m_resonance_avoidance = true;[m
      }[m
[31m -    if (EXTRUDER_CONFIG(filament_max_volumetric_speed) > 0) {[m
[31m -        // cap speed with max_volumetric_speed anyway (even if user is not using autospeed)[m
[31m -        speed = std::min([m
[31m -            speed,[m
[31m -            EXTRUDER_CONFIG(filament_max_volumetric_speed) / path.mm3_per_mm[m
[31m -        );[m
[32m +}[m
[32m +    [m
[32m +    bool variable_speed = false;[m
[32m +    std::vector<ProcessedPoint> new_points {};[m
[32m +[m
[32m +    if (m_config.enable_overhang_speed && !this->on_first_layer() &&[m
[32m +        (is_bridge(path.role()) || is_perimeter(path.role()))) {[m
[32m +            bool is_external = is_external_perimeter(path.role());[m
[32m +            double ref_speed   = is_external ? m_config.get_abs_value("outer_wall_speed") : m_config.get_abs_value("inner_wall_speed");[m
[32m +            if (ref_speed == 0)[m
[32m +                ref_speed = FILAMENT_CONFIG(filament_max_volumetric_speed) / _mm3_per_mm;[m
[32m +[m
[32m +            if (EXTRUDER_CONFIG(filament_max_volumetric_speed) > 0) {[m
[32m +                ref_speed = std::min(ref_speed, FILAMENT_CONFIG(filament_max_volumetric_speed) / _mm3_per_mm);[m
[32m +            }[m
[32m +            if (sloped) {[m
[32m +                ref_speed = std::min(ref_speed, m_config.scarf_joint_speed.get_abs_value(ref_speed));[m
[32m +            }[m
[32m +            [m
[32m +            ConfigOptionPercents         overhang_overlap_levels({90, 75, 50, 25, 13, 0});[m
[32m +[m
[32m +            if (m_config.slowdown_for_curled_perimeters){[m
[32m +                ConfigOptionFloatsOrPercents dynamic_overhang_speeds([m
[32m +                    {FloatOrPercent{100, true},[m
[32m +                     (m_config.get_abs_value("overhang_1_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_1_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                     (m_config.get_abs_value("overhang_2_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_2_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                     (m_config.get_abs_value("overhang_3_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_3_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                     (m_config.get_abs_value("overhang_4_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_4_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                     (m_config.get_abs_value("overhang_4_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_4_4_speed", ref_speed) * 100 / ref_speed, true}});[m
[32m +[m
[32m +                new_points = m_extrusion_quality_estimator.estimate_extrusion_quality(path, overhang_overlap_levels, dynamic_overhang_speeds,[m
[32m +                                                                              ref_speed, speed, m_config.slowdown_for_curled_perimeters);[m
[32m +        	}else{[m
[32m +                ConfigOptionFloatsOrPercents dynamic_overhang_speeds([m
[32m +                                                                     {FloatOrPercent{100, true},[m
[32m +                     (m_config.get_abs_value("overhang_1_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_1_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                     (m_config.get_abs_value("overhang_2_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_2_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                     (m_config.get_abs_value("overhang_3_4_speed", ref_speed) < 0.5) ?[m
[32m +                         FloatOrPercent{100, true} :[m
[32m +                         FloatOrPercent{m_config.get_abs_value("overhang_3_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                      (m_config.get_abs_value("overhang_4_4_speed", ref_speed) < 0.5) ?[m
[32m +                            FloatOrPercent{100, true} :[m
[32m +                            FloatOrPercent{m_config.get_abs_value("overhang_4_4_speed", ref_speed) * 100 / ref_speed, true},[m
[32m +                     FloatOrPercent{m_config.get_abs_value("bridge_speed") * 100 / ref_speed, true}});[m
[32m +[m
[32m +                new_points = m_extrusion_quality_estimator.estimate_extrusion_quality(path, overhang_overlap_levels, dynamic_overhang_speeds,[m
[32m +                                                                              ref_speed, speed, m_config.slowdown_for_curled_perimeters);[m
[32m +            }[m
[32m +            variable_speed = std::any_of(new_points.begin(), new_points.end(),[m
[32m +                                         [speed](const ProcessedPoint &p) { return fabs(double(p.speed) - speed) > 1; }); // Ignore small speed variations (under 1mm/sec)[m
      }[m
[32m +[m
      double F = speed * 60;  // convert mm/sec to mm/min[m
[32m +    [m
[32m +    // Orca: Dynamic PA[m
[32m +    // If adaptive PA is enabled, by default evaluate PA on all extrusion moves[m
[32m +    bool is_pa_calib = m_curr_print->calib_mode() == CalibMode::Calib_PA_Line ||[m
[32m +                       m_curr_print->calib_mode() == CalibMode::Calib_PA_Pattern ||[m
[32m +                       m_curr_print->calib_mode() == CalibMode::Calib_PA_Tower; [m
[32m +    bool evaluate_adaptive_pa = false;[m
[32m +    bool role_change = (m_last_extrusion_role != path.role());[m
[32m +    if (!is_pa_calib && FILAMENT_CONFIG(adaptive_pressure_advance) && FILAMENT_CONFIG(enable_pressure_advance)) {[m
[32m +        evaluate_adaptive_pa = true;[m
[32m +        // If we have already emmited a PA change because the m_multi_flow_segment_path_pa_set is set[m
[32m +        // skip re-issuing the PA change tag.[m
[32m +        if (m_multi_flow_segment_path_pa_set && evaluate_adaptive_pa)[m
[32m +            evaluate_adaptive_pa = false;[m
[32m +        // TODO: Explore forcing evaluation of PA if a role change is happening mid extrusion.[m
[32m +        // TODO: This would enable adapting PA for overhang perimeters as they are part of the current loop[m
[32m +        // TODO: The issue with simply enabling PA evaluation on a role change is that the speed change[m
[32m +        // TODO: is issued before the overhang perimeter role change is triggered[m
[32m +        // TODO: because for some reason (maybe path segmentation upstream?) there is a short path extruded[m
[32m +        // TODO: with the overhang speed and flow before the role change is flagged in the path.role() function.[m
[32m +        if(role_change)[m
[32m +            evaluate_adaptive_pa = true;[m
[32m +    }[m
[32m +    // Orca: End of dynamic PA trigger flag segment[m
[32m +    [m
[32m +    //Orca: process custom gcode for extrusion role change[m
[32m +    if (path.role() != m_last_extrusion_role && !m_config.change_extrusion_role_gcode.value.empty()) {[m
[32m +            DynamicConfig config;[m
[32m +            config.set_key_value("extrusion_role", new ConfigOptionString(extrusion_role_to_string_for_parser(path.role())));[m
[32m +            config.set_key_value("last_extrusion_role", new ConfigOptionString(extrusion_role_to_string_for_parser(m_last_extrusion_role)));[m
[32m +            config.set_key_value("layer_num", new ConfigOptionInt(m_layer_index + 1));[m
[32m +            config.set_key_value("layer_z", new ConfigOptionFloat(m_layer == nullptr ? m_last_height : m_layer->print_z));[m
[32m +            gcode += this->placeholder_parser_process("change_extrusion_role_gcode",[m
[32m +                                                      m_config.change_extrusion_role_gcode.value, m_writer.filament()->id(), &config)[m
[32m +                     + "\n";[m
[32m +    }[m
  [m
      // extrude arc or line[m
[31m -    if (m_enable_extrusion_role_markers)[m
[31m -    {[m
[31m -        if (path.role() != m_last_extrusion_role)[m
[31m -        {[m
[31m -            m_last_extrusion_role = path.role();[m
[31m -            if (m_enable_extrusion_role_markers)[m
[31m -            {[m
[31m -                char buf[32];[m
[31m -                sprintf(buf, ";_EXTRUSION_ROLE:%d\n", int(m_last_extrusion_role));[m
[31m -                gcode += buf;[m
[31m -            }[m
[31m -        }[m
[32m +    if (m_enable_extrusion_role_markers) {[m
[32m +        if (path.role() != m_last_extrusion_role) {[m
[32m +            char buf[32];[m
[32m +            sprintf(buf, ";_EXTRUSION_ROLE:%d\n", int(path.role()));[m
[32m +            gcode += buf;[m
[32m +      }[m
      }[m
  [m
[32m +    m_last_extrusion_role = path.role();[m
[32m +[m
      // adds processor tags and updates processor tracking data[m
      // PrusaMultiMaterial::Writer may generate GCodeProcessor::Height_Tag lines without updating m_last_height[m
      // so, if the last role was erWipeTower we force export of GCodeProcessor::Height_Tag lines[m
[1mdiff --cc src/libslic3r/GCode.hpp[m
[1mindex d379300bad,d2d241054f..0000000000[m
[1m--- a/src/libslic3r/GCode.hpp[m
[1m+++ b/src/libslic3r/GCode.hpp[m
[36m@@@ -190,10 -124,10 +190,17 @@@[m [mpublic[m
          m_enable_extrusion_role_markers(false),[m
          m_last_processor_extrusion_role(erNone),[m
          m_layer_count(0),[m
[32m++<<<<<<< HEAD[m
[32m +        m_layer_index(-1),[m
[32m +        m_layer(nullptr),[m
[32m +        m_object_layer_over_raft(false),[m
[32m +        //m_volumetric_speed(0),[m
[32m++=======[m
[32m+         m_layer_index(-1), [m
[32m+         m_layer(nullptr),[m
[32m+         m_object_layer_over_raft(false),[m
[32m+         m_volumetric_speed(0),[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
          m_last_pos_defined(false),[m
          m_last_extrusion_role(erNone),[m
          m_last_width(0.0f),[m
[36m@@@ -562,11 -322,9 +569,15 @@@[m [mprivate[m
      const Layer*                        m_layer;[m
      // m_layer is an object layer and it is being printed over raft surface.[m
      bool                                m_object_layer_over_raft;[m
[32m++<<<<<<< HEAD[m
[32m +    //double                              m_volumetric_speed;[m
[32m++=======[m
[32m+     double                              m_volumetric_speed;[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
      // Support for the extrusion role markers. Which marker is active?[m
      ExtrusionRole                       m_last_extrusion_role;[m
[32m +    // To ignore gapfill role for retract_lift_enforce[m
[32m +    ExtrusionRole                       m_last_notgapfill_extrusion_role;[m
      // Support for G-Code Processor[m
      float                               m_last_height{ 0.0f };[m
      float                               m_last_layer_z{ 0.0f };[m
[36m@@@ -620,37 -358,24 +631,41 @@@[m
      // Processor[m
      GCodeProcessor m_processor;[m
  [m
[31m -    // Write a string into a file.[m
[31m -    void _write(FILE* file, const std::string& what) { this->_write(file, what.c_str()); }[m
[31m -    void _write(FILE* file, const char *what);[m
[32m +    //some post-processing on the file, with their data class[m
[32m +    std::unique_ptr<FanMover> m_fan_mover;[m
  [m
[31m -    // Write a string into a file. [m
[31m -    // Add a newline, if the string does not end with a newline already.[m
[31m -    // Used to export a custom G-code section processed by the PlaceholderParser.[m
[31m -    void _writeln(FILE* file, const std::string& what);[m
[32m +    // BBS[m
[32m +    Print* m_curr_print = nullptr;[m
[32m +    unsigned int m_toolchange_count;[m
[32m +    coordf_t m_nominal_z;[m
[32m +    bool m_need_change_layer_lift_z = false;[m
[32m +    int m_start_gcode_filament = -1;[m
[32m +    std::string m_filament_instances_code;[m
  [m
[31m -    // Formats and write into a file the given data. [m
[31m -    void _write_format(FILE* file, const char* format, ...);[m
[32m +    std::set<unsigned int>                  m_initial_layer_extruders;[m
[32m +    std::vector<std::vector<unsigned int>>  m_sorted_layer_filaments;[m
[32m +    // BBS[m
[32m +    int get_bed_temperature(const int extruder_id, const bool is_first_layer, const BedType bed_type) const;[m
[32m +    int get_highest_bed_temperature(const bool is_first_layer,const Print &print) const;[m
  [m
[32m +    double      calc_max_volumetric_speed(const double layer_height, const double line_width, const std::string co_str);[m
      std::string _extrude(const ExtrusionPath &path, std::string description = "", double speed = -1);[m
[31m -    void print_machine_envelope(FILE *file, Print &print);[m
[31m -    void _print_first_layer_bed_temperature(FILE *file, Print &print, const std::string &gcode, unsigned int first_printing_extruder_id, bool wait);[m
[31m -    void _print_first_layer_extruder_temperatures(FILE *file, Print &print, const std::string &gcode, unsigned int first_printing_extruder_id, bool wait);[m
[32m +    bool _needSAFC(const ExtrusionPath &path);[m
[32m +    void print_machine_envelope(GCodeOutputStream& file, Print& print);[m
[32m +    void _print_first_layer_bed_temperature(GCodeOutputStream &file, Print &print, const std::string &gcode, unsigned int first_printing_extruder_id, bool wait);[m
[32m +    void _print_first_layer_extruder_temperatures(GCodeOutputStream &file, Print &print, const std::string &gcode, unsigned int first_printing_extruder_id, bool wait);[m
      // On the first printing layer. This flag triggers first layer speeds.[m
[32m++<<<<<<< HEAD[m
[32m +    //BBS[m
[32m +    bool    on_first_layer() const { return m_layer != nullptr && m_layer->id() == 0 && abs(m_layer->bottom_z()) < EPSILON; }[m
[32m +    int layer_id() const {[m
[32m +        if (m_layer == nullptr)[m
[32m +            return -1;[m
[32m +        return m_layer->id();[m
[32m +    }[m
[32m++=======[m
[32m+     bool                                on_first_layer() const { return m_layer != nullptr && m_layer->id() == 0; }[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
      // To control print speed of 1st object layer over raft interface.[m
      bool                                object_layer_over_raft() const { return m_object_layer_over_raft; }[m
  [m
[1mdiff --cc src/libslic3r/Preset.cpp[m
[1mindex 73e4ce9181,f5c8235ed5..0000000000[m
[1m--- a/src/libslic3r/Preset.cpp[m
[1m+++ b/src/libslic3r/Preset.cpp[m
[36m@@@ -888,114 -414,53 +888,148 @@@[m [mbool Preset::has_cali_lines(PresetBundl[m
  }[m
  [m
  static std::vector<std::string> s_Preset_print_options {[m
[32m++<<<<<<< HEAD[m
[32m +    "layer_height", "initial_layer_print_height", "wall_loops", "alternate_extra_wall", "slice_closing_radius", "spiral_mode", "spiral_mode_smooth", "spiral_mode_max_xy_smoothing", "spiral_starting_flow_ratio", "spiral_finishing_flow_ratio", "slicing_mode",[m
[32m +    "top_shell_layers", "top_shell_thickness", "top_surface_density", "bottom_surface_density", "bottom_shell_layers", "bottom_shell_thickness",[m
[32m +    "extra_perimeters_on_overhangs", "ensure_vertical_shell_thickness", "reduce_crossing_wall", "detect_thin_wall", "detect_overhang_wall", "overhang_reverse", "overhang_reverse_threshold","overhang_reverse_internal_only", "wall_direction",[m
[32m +    "seam_position", "staggered_inner_seams", "wall_sequence", "is_infill_first", "sparse_infill_density","fill_multiline", "sparse_infill_pattern", "lateral_lattice_angle_1", "lateral_lattice_angle_2", "infill_overhang_angle", "top_surface_pattern", "bottom_surface_pattern",[m
[32m +    "infill_direction", "solid_infill_direction", "counterbore_hole_bridging","infill_shift_step", "sparse_infill_rotate_template", "solid_infill_rotate_template", "symmetric_infill_y_axis","skeleton_infill_density", "infill_lock_depth", "skin_infill_depth", "skin_infill_density",[m
[32m +    "align_infill_direction_to_model", "extra_solid_infills",[m
[32m +    "minimum_sparse_infill_area", "reduce_infill_retraction","internal_solid_infill_pattern","gap_fill_target",[m
[32m +    "ironing_type", "ironing_pattern", "ironing_flow", "ironing_speed", "ironing_spacing", "ironing_angle", "ironing_angle_fixed", "ironing_inset",[m
[32m +    "support_ironing", "support_ironing_pattern", "support_ironing_flow", "support_ironing_spacing",[m
[32m +    "max_travel_detour_distance",[m
[32m +    "fuzzy_skin", "fuzzy_skin_thickness", "fuzzy_skin_point_distance", "fuzzy_skin_first_layer", "fuzzy_skin_noise_type", "fuzzy_skin_mode", "fuzzy_skin_scale", "fuzzy_skin_octaves", "fuzzy_skin_persistence",[m
[32m +    "max_volumetric_extrusion_rate_slope", "max_volumetric_extrusion_rate_slope_segment_length","extrusion_rate_smoothing_external_perimeter_only",[m
[32m +    "inner_wall_speed", "outer_wall_speed", "sparse_infill_speed", "internal_solid_infill_speed",[m
[32m +    "top_surface_speed", "support_speed", "support_object_xy_distance", "support_object_first_layer_gap", "support_interface_speed",[m
[32m +    "bridge_speed", "internal_bridge_speed", "gap_infill_speed", "travel_speed", "travel_speed_z", "initial_layer_speed",[m
[32m +    "outer_wall_acceleration", "initial_layer_acceleration", "top_surface_acceleration", "default_acceleration", "skirt_type", "skirt_loops", "skirt_speed","min_skirt_length", "skirt_distance", "skirt_start_angle", "skirt_height","single_loop_draft_shield", "draft_shield",[m
[32m +    "brim_width", "brim_object_gap", "brim_use_efc_outline", "combine_brims", "brim_type", "brim_ears_max_angle", "brim_ears_detection_length", "enable_support", "support_type", "support_threshold_angle", "support_threshold_overlap","enforce_support_layers",[m
[32m +    "raft_layers", "raft_first_layer_density", "raft_first_layer_expansion", "raft_contact_distance", "raft_expansion","raft_base_density", "raft_interface_density", "raft_advanced_params",[m
[32m +    "support_base_pattern", "support_base_pattern_spacing", "support_expansion", "support_style",[m
[32m +    // BBS[m
[32m +    "print_extruder_id", "print_extruder_variant",[m
[32m +    "independent_support_layer_height",[m
[32m +    "support_angle", "support_interface_top_layers", "support_interface_bottom_layers",[m
[32m +    "support_interface_pattern", "support_interface_spacing", "support_interface_loop_pattern",[m
[32m +    "support_top_z_distance", "support_on_build_plate_only","support_critical_regions_only", "bridge_no_support", "thick_bridges", "thick_internal_bridges","dont_filter_internal_bridges","enable_extra_bridge_layer", "max_bridge_length", "print_sequence", "print_order", "support_remove_small_overhang",[m
[32m +    "filename_format", "wall_filament", "support_bottom_z_distance",[m
[32m +    "sparse_infill_filament", "solid_infill_filament", "support_filament", "support_interface_filament","support_interface_not_for_body",[m
[32m +    "ooze_prevention", "standby_temperature_delta", "preheat_time","preheat_steps", "interface_shells", "line_width", "initial_layer_line_width", "inner_wall_line_width",[m
[32m +    "outer_wall_line_width", "sparse_infill_line_width", "internal_solid_infill_line_width",[m
[32m +    "skin_infill_line_width","skeleton_infill_line_width",[m
[32m +    "top_surface_line_width", "support_line_width", "infill_wall_overlap","top_bottom_infill_wall_overlap", "bridge_flow", "internal_bridge_flow",[m
[32m +    "elefant_foot_compensation", "elefant_foot_compensation_layers", "xy_contour_compensation", "xy_hole_compensation", "resolution", "enable_prime_tower", "prime_tower_enable_framework",[m
[32m +    "prime_tower_width", "prime_tower_brim_width", "prime_tower_skip_points", "prime_volume",[m
[32m +    "prime_tower_infill_gap",[m
[32m +    "prime_tower_flat_ironing",[m
[32m +    "enable_tower_interface_features",[m
[32m +    "enable_tower_interface_cooldown_during_tower",[m
[32m +    "wipe_tower_no_sparse_layers", "compatible_printers", "compatible_printers_condition", "inherits",[m
[32m +    "flush_into_infill", "flush_into_objects", "flush_into_support",[m
[32m +     "tree_support_branch_angle", "tree_support_angle_slow", "tree_support_wall_count", "tree_support_top_rate", "tree_support_branch_distance", "tree_support_tip_diameter",[m
[32m +     "tree_support_branch_diameter", "tree_support_branch_diameter_angle",[m
[32m +     "detect_narrow_internal_solid_infill",[m
[32m +     "gcode_add_line_number", "enable_arc_fitting", "precise_z_height", "infill_combination","infill_combination_max_layer_height", /*"adaptive_layer_height",*/[m
[32m +     "support_bottom_interface_spacing", "enable_overhang_speed", "slowdown_for_curled_perimeters", "overhang_1_4_speed", "overhang_2_4_speed", "overhang_3_4_speed", "overhang_4_4_speed",[m
[32m +     "initial_layer_infill_speed", "only_one_wall_top", [m
[32m +     "timelapse_type",[m
[32m +     "wall_generator", "wall_transition_length", "wall_transition_filter_deviation", "wall_transition_angle",[m
[32m +     "wall_distribution_count", "min_feature_size", "min_bead_width", "post_process", "min_length_factor",[m
[32m +     "small_perimeter_speed", "small_perimeter_threshold","bridge_angle","internal_bridge_angle", "filter_out_gap_fill", "travel_acceleration","inner_wall_acceleration", "min_width_top_surface",[m
[32m +     "default_jerk", "outer_wall_jerk", "inner_wall_jerk", "infill_jerk", "top_surface_jerk", "initial_layer_jerk","travel_jerk","default_junction_deviation",[m
[32m +     "top_solid_infill_flow_ratio","bottom_solid_infill_flow_ratio","only_one_wall_first_layer", "print_flow_ratio", "seam_gap",[m
[32m +     "set_other_flow_ratios", "first_layer_flow_ratio", "outer_wall_flow_ratio", "inner_wall_flow_ratio", "overhang_flow_ratio", "sparse_infill_flow_ratio", "internal_solid_infill_flow_ratio", "gap_fill_flow_ratio", "support_flow_ratio", "support_interface_flow_ratio", [m
[32m +     "role_based_wipe_speed", "wipe_speed", "accel_to_decel_enable", "accel_to_decel_factor", "wipe_on_loops", "wipe_before_external_loop",[m
[32m +     "bridge_density","internal_bridge_density", "precise_outer_wall", "bridge_acceleration",[m
[32m +     "sparse_infill_acceleration", "internal_solid_infill_acceleration", "tree_support_auto_brim", [m
[32m +     "tree_support_brim_width", "gcode_comments", "gcode_label_objects",[m
[32m +     "initial_layer_travel_speed", "exclude_object", "slow_down_layers", "infill_anchor", "infill_anchor_max","initial_layer_min_bead_width",[m
[32m +     "make_overhang_printable", "make_overhang_printable_angle", "make_overhang_printable_hole_size" ,"notes",[m
[32m +     "wipe_tower_cone_angle", "wipe_tower_extra_spacing","wipe_tower_max_purge_speed", [m
[32m +     "wipe_tower_wall_type", "wipe_tower_extra_rib_length", "wipe_tower_rib_width", "wipe_tower_fillet_wall",[m
[32m +     "wipe_tower_filament", "wiping_volumes_extruders","wipe_tower_bridging", "wipe_tower_extra_flow","single_extruder_multi_material_priming",[m
[32m +     "wipe_tower_rotation_angle", "tree_support_branch_distance_organic", "tree_support_branch_diameter_organic", "tree_support_branch_angle_organic",[m
[32m +     "hole_to_polyhole", "hole_to_polyhole_threshold", "hole_to_polyhole_twisted", "mmu_segmented_region_max_width", "mmu_segmented_region_interlocking_depth",[m
[32m +     "small_area_infill_flow_compensation", "small_area_infill_flow_compensation_model",[m
[32m +     "enable_wrapping_detection",[m
[32m +     "seam_slope_type", "seam_slope_conditional", "scarf_angle_threshold", "scarf_joint_speed", "scarf_joint_flow_ratio", "seam_slope_start_height", "seam_slope_entire_loop", "seam_slope_min_length", "seam_slope_steps", "seam_slope_inner_walls", "scarf_overhang_threshold",[m
[32m +     "interlocking_beam", "interlocking_orientation", "interlocking_beam_layer_count", "interlocking_depth", "interlocking_boundary_avoidance", "interlocking_beam_width","calib_flowrate_topinfill_special_order",[m
[32m++=======[m
[32m+     "layer_height", "first_layer_height", "perimeters", "spiral_vase", "slice_closing_radius", "slicing_mode",[m
[32m+     "top_solid_layers", "top_solid_min_thickness", "bottom_solid_layers", "bottom_solid_min_thickness",[m
[32m+     "extra_perimeters", "ensure_vertical_shell_thickness", "avoid_crossing_perimeters", "thin_walls", "overhangs",[m
[32m+     "seam_position", "external_perimeters_first", "fill_density", "fill_pattern", "top_fill_pattern", "bottom_fill_pattern",[m
[32m+     "infill_every_layers", "infill_only_where_needed", "solid_infill_every_layers", "fill_angle", "bridge_angle",[m
[32m+     "solid_infill_below_area", "only_retract_when_crossing_perimeters", "infill_first",[m
[32m+     "ironing", "ironing_type", "ironing_flowrate", "ironing_speed", "ironing_spacing",[m
[32m+     "max_print_speed", "max_volumetric_speed", "avoid_crossing_perimeters_max_detour",[m
[32m+     "fuzzy_skin", "fuzzy_skin_thickness", "fuzzy_skin_point_dist",[m
[32m+ #ifdef HAS_PRESSURE_EQUALIZER[m
[32m+     "max_volumetric_extrusion_rate_slope_positive", "max_volumetric_extrusion_rate_slope_negative",[m
[32m+ #endif /* HAS_PRESSURE_EQUALIZER */[m
[32m+     "perimeter_speed", "small_perimeter_speed", "external_perimeter_speed", "infill_speed", "solid_infill_speed",[m
[32m+     "top_solid_infill_speed", "support_material_speed", "support_material_xy_spacing", "support_material_interface_speed",[m
[32m+     "bridge_speed", "gap_fill_speed", "gap_fill_enabled", "travel_speed", "travel_speed_z", "first_layer_speed", "first_layer_speed_over_raft", "perimeter_acceleration", "infill_acceleration",[m
[32m+     "bridge_acceleration", "first_layer_acceleration", "first_layer_acceleration_over_raft", "default_acceleration", "skirts", "skirt_distance", "skirt_height", "draft_shield",[m
[32m+     "min_skirt_length", "brim_width", "brim_separation", "brim_type", "support_material", "support_material_auto", "support_material_threshold", "support_material_enforce_layers",[m
[32m+     "raft_layers", "raft_first_layer_density", "raft_first_layer_expansion", "raft_contact_distance", "raft_expansion",[m
[32m+     "support_material_pattern", "support_material_with_sheath", "support_material_spacing", "support_material_closing_radius", "support_material_style",[m
[32m+     "support_material_synchronize_layers", "support_material_angle", "support_material_interface_layers", "support_material_bottom_interface_layers",[m
[32m+     "support_material_interface_pattern", "support_material_interface_spacing", "support_material_interface_contact_loops", [m
[32m+     "support_material_contact_distance", "support_material_bottom_contact_distance",[m
[32m+     "support_material_buildplate_only", "dont_support_bridges", "thick_bridges", "notes", "complete_objects", "extruder_clearance_radius",[m
[32m+     "extruder_clearance_height", "gcode_comments", "gcode_label_objects", "output_filename_format", "post_process", "perimeter_extruder",[m
[32m+     "infill_extruder", "solid_infill_extruder", "support_material_extruder", "support_material_interface_extruder",[m
[32m+     "ooze_prevention", "standby_temperature_delta", "interface_shells", "extrusion_width", "first_layer_extrusion_width",[m
[32m+     "perimeter_extrusion_width", "external_perimeter_extrusion_width", "infill_extrusion_width", "solid_infill_extrusion_width",[m
[32m+     "top_infill_extrusion_width", "support_material_extrusion_width", "infill_overlap", "infill_anchor", "infill_anchor_max", "bridge_flow_ratio", "clip_multipart_objects",[m
[32m+     "elefant_foot_compensation", "xy_size_compensation", "threads", "resolution", "wipe_tower", "wipe_tower_x", "wipe_tower_y",[m
[32m+     "wipe_tower_width", "wipe_tower_rotation_angle", "wipe_tower_brim_width", "wipe_tower_bridging", "single_extruder_multi_material_priming", "mmu_segmented_region_max_width",[m
[32m+     "wipe_tower_no_sparse_layers", "compatible_printers", "compatible_printers_condition", "inherits"[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
  };[m
  [m
[31m -static std::vector<std::string> s_Preset_filament_options {[m
[31m -    "filament_colour", "filament_diameter", "filament_type", "filament_soluble", "filament_notes", "filament_max_volumetric_speed",[m
[31m -    "extrusion_multiplier", "filament_density", "filament_cost", "filament_spool_weight", "filament_loading_speed", "filament_loading_speed_start", "filament_load_time",[m
[31m -    "filament_unloading_speed", "filament_unloading_speed_start", "filament_unload_time", "filament_toolchange_delay", "filament_cooling_moves",[m
[31m -    "filament_cooling_initial_speed", "filament_cooling_final_speed", "filament_ramming_parameters", "filament_minimal_purge_on_wipe_tower",[m
[31m -    "temperature", "first_layer_temperature", "bed_temperature", "first_layer_bed_temperature", "fan_always_on", "cooling", "min_fan_speed",[m
[31m -    "max_fan_speed", "bridge_fan_speed", "disable_fan_first_layers", "full_fan_speed_layer", "fan_below_layer_time", "slowdown_below_layer_time", "min_print_speed",[m
[31m -    "start_filament_gcode", "end_filament_gcode",[m
[32m +static std::vector<std::string> s_Preset_filament_options {/*"filament_colour", */ "default_filament_colour", "required_nozzle_HRC", "filament_diameter", "pellet_flow_coefficient", "volumetric_speed_coefficients", "filament_type",[m
[32m +                                                          "filament_soluble", "filament_is_support", "filament_printable",[m
[32m +    "filament_max_volumetric_speed", "filament_adaptive_volumetric_speed",[m
[32m +    "filament_flow_ratio", "filament_density", "filament_adhesiveness_category", "filament_cost", "filament_minimal_purge_on_wipe_tower",[m
[32m +    "filament_tower_interface_pre_extrusion_dist", "filament_tower_interface_pre_extrusion_length", "filament_tower_ironing_area", "filament_tower_interface_purge_volume",[m
[32m +    "filament_tower_interface_print_temp",[m
[32m +    "nozzle_temperature", "nozzle_temperature_initial_layer",[m
[32m +    // BBS[m
[32m +    "cool_plate_temp", "textured_cool_plate_temp", "eng_plate_temp", "hot_plate_temp", "textured_plate_temp", "cool_plate_temp_initial_layer", "textured_cool_plate_temp_initial_layer", "eng_plate_temp_initial_layer", "hot_plate_temp_initial_layer", "textured_plate_temp_initial_layer", "supertack_plate_temp_initial_layer", "supertack_plate_temp",[m
[32m +    // "bed_type",[m
[32m +    //BBS:temperature_vitrification[m
[32m +    "temperature_vitrification", "reduce_fan_stop_start_freq","dont_slow_down_outer_wall", "slow_down_for_layer_cooling", "fan_min_speed",[m
[32m +    "fan_max_speed", "enable_overhang_bridge_fan", "overhang_fan_speed", "overhang_fan_threshold", "close_fan_the_first_x_layers", "full_fan_speed_layer", "fan_cooling_layer_time", "slow_down_layer_time", "slow_down_min_speed",[m
[32m +    "filament_start_gcode", "filament_end_gcode",[m
[32m +    //exhaust fan control[m
[32m +    "activate_air_filtration","during_print_exhaust_fan_speed","complete_print_exhaust_fan_speed",[m
      // Retract overrides[m
[31m -    "filament_retract_length", "filament_retract_lift", "filament_retract_lift_above", "filament_retract_lift_below", "filament_retract_speed", "filament_deretract_speed", "filament_retract_restart_extra", "filament_retract_before_travel",[m
[31m -    "filament_retract_layer_change", "filament_wipe", "filament_retract_before_wipe",[m
[32m +    "filament_retraction_length", "filament_z_hop", "filament_z_hop_types", "filament_retract_lift_above", "filament_retract_lift_below", "filament_retract_lift_enforce", "filament_retraction_speed", "filament_deretraction_speed", "filament_retract_restart_extra", "filament_retraction_minimum_travel",[m
[32m +    "filament_retract_when_changing_layer", "filament_wipe", "filament_retract_before_wipe",[m
      // Profile compatibility[m
[31m -    "filament_vendor", "compatible_prints", "compatible_prints_condition", "compatible_printers", "compatible_printers_condition", "inherits"[m
[31m -};[m
[32m +    "filament_vendor", "compatible_prints", "compatible_prints_condition", "compatible_printers", "compatible_printers_condition", "inherits",[m
[32m +    //BBS[m
[32m +    "filament_wipe_distance", "additional_cooling_fan_speed",[m
[32m +    "nozzle_temperature_range_low", "nozzle_temperature_range_high",[m
[32m +    "filament_extruder_variant",[m
[32m +    //SoftFever[m
[32m +    "enable_pressure_advance", "pressure_advance","adaptive_pressure_advance","adaptive_pressure_advance_model","adaptive_pressure_advance_overhangs", "adaptive_pressure_advance_bridges","chamber_temperature", "filament_shrink","filament_shrinkage_compensation_z", "support_material_interface_fan_speed","internal_bridge_fan_speed", "filament_notes" /*,"filament_seam_gap"*/,[m
[32m +    "ironing_fan_speed",[m
[32m +    // Filament ironing overrides[m
[32m +    "filament_ironing_flow", "filament_ironing_spacing", "filament_ironing_inset", "filament_ironing_speed",[m
[32m +    "filament_loading_speed", "filament_loading_speed_start",[m
[32m +    "filament_unloading_speed", "filament_unloading_speed_start", "filament_toolchange_delay", "filament_cooling_moves", "filament_stamping_loading_speed", "filament_stamping_distance",[m
[32m +    "filament_cooling_initial_speed", "filament_cooling_final_speed", "filament_ramming_parameters",[m
[32m +    "filament_multitool_ramming", "filament_multitool_ramming_volume", "filament_multitool_ramming_flow", "activate_chamber_temp_control",[m
[32m +    "filament_long_retractions_when_cut","filament_retraction_distances_when_cut", "idle_temperature",[m
[32m +    //BBS filament change length while the extruder color[m
[32m +    "filament_change_length","filament_flush_volumetric_speed","filament_flush_temp",[m
[32m +    "long_retractions_when_ec", "retraction_distances_when_ec"[m
[32m +    };[m
  [m
  static std::vector<std::string> s_Preset_machine_limits_options {[m
      "machine_max_acceleration_extruding", "machine_max_acceleration_retracting", "machine_max_acceleration_travel",[m
[1mdiff --cc src/libslic3r/Print.cpp[m
[1mindex 6463338f7d,06052a62f3..0000000000[m
[1m--- a/src/libslic3r/Print.cpp[m
[1m+++ b/src/libslic3r/Print.cpp[m
[36m@@@ -99,142 -56,84 +99,171 @@@[m [mbool Print::invalidate_state_by_config_[m
      // Cache the plenty of parameters, which influence the G-code generator only,[m
      // or they are only notes not influencing the generated G-code.[m
      static std::unordered_set<std::string> steps_gcode = {[m
[31m -        "avoid_crossing_perimeters",[m
[31m -        "avoid_crossing_perimeters_max_detour",[m
[31m -        "bed_shape",[m
[31m -        "bed_temperature",[m
[31m -        "before_layer_gcode",[m
[31m -        "between_objects_gcode",[m
[31m -        "bridge_acceleration",[m
[31m -        "bridge_fan_speed",[m
[31m -        "colorprint_heights",[m
[31m -        "cooling",[m
[32m +        //BBS[m
[32m +        "additional_cooling_fan_speed",[m
[32m +        "reduce_crossing_wall",[m
[32m +        "max_travel_detour_distance",[m
[32m +        "printable_area",[m
[32m +        //BBS: add bed_exclude_area[m
[32m +        "bed_exclude_area",[m
[32m +        "thumbnail_size",[m
[32m +        "before_layer_change_gcode",[m
[32m +        "enable_pressure_advance",[m
[32m +        "pressure_advance",[m
[32m +        "enable_overhang_bridge_fan",[m
[32m +        "overhang_fan_speed",[m
[32m +        "overhang_fan_threshold",[m
[32m +        "slow_down_for_layer_cooling",[m
          "default_acceleration",[m
[31m -        "deretract_speed",[m
[31m -        "disable_fan_first_layers",[m
[31m -        "duplicate_distance",[m
[31m -        "end_gcode",[m
[31m -        "end_filament_gcode",[m
[31m -        "extrusion_axis",[m
[31m -        "extruder_clearance_height",[m
[32m +        "deretraction_speed",[m
[32m +        "close_fan_the_first_x_layers",[m
[32m +        "machine_end_gcode",[m
[32m +        "printing_by_object_gcode",[m
[32m +        "filament_end_gcode",[m
[32m +        "post_process",[m
[32m +        "extruder_clearance_height_to_rod",[m
[32m +        "extruder_clearance_height_to_lid",[m
          "extruder_clearance_radius",[m
[32m +        "nozzle_height",[m
          "extruder_colour",[m
          "extruder_offset",[m
[31m -        "extrusion_multiplier",[m
[31m -        "fan_always_on",[m
[31m -        "fan_below_layer_time",[m
[32m +        "filament_flow_ratio",[m
[32m +        "reduce_fan_stop_start_freq",[m
[32m +        "dont_slow_down_outer_wall",[m
[32m +        "fan_cooling_layer_time",[m
          "full_fan_speed_layer",[m
[32m +        "fan_kickstart",[m
[32m +        "fan_speedup_overhangs",[m
[32m +        "fan_speedup_time",[m
          "filament_colour",[m
[32m +        "default_filament_colour",[m
          "filament_diameter",[m
[32m +         "volumetric_speed_coefficients",[m
          "filament_density",[m
[31m -        "filament_notes",[m
          "filament_cost",[m
[32m++<<<<<<< HEAD[m
[32m +        "filament_notes",[m
[32m +        "outer_wall_acceleration",[m
[32m +        "inner_wall_acceleration",[m
[32m +        "initial_layer_acceleration",[m
[32m +        "top_surface_acceleration",[m
[32m +        "bridge_acceleration",[m
[32m +        "travel_acceleration",[m
[32m +        "sparse_infill_acceleration",[m
[32m +        "internal_solid_infill_acceleration",[m
[32m +        // BBS[m
[32m +        "supertack_plate_temp_initial_layer",[m
[32m +        "cool_plate_temp_initial_layer",[m
[32m +        "textured_cool_plate_temp_initial_layer",[m
[32m +        "eng_plate_temp_initial_layer",[m
[32m +        "hot_plate_temp_initial_layer",[m
[32m +        "textured_plate_temp_initial_layer",[m
[32m +        "gcode_add_line_number",[m
[32m +        "layer_change_gcode",[m
[32m +        "time_lapse_gcode",[m
[32m +        "wrapping_detection_gcode",[m
[32m +        "fan_min_speed",[m
[32m +        "fan_max_speed",[m
[32m +        "printable_height",[m
[32m +        "slow_down_min_speed",[m
[32m +        "max_volumetric_extrusion_rate_slope",[m
[32m +        "max_volumetric_extrusion_rate_slope_segment_length",[m
[32m +        "extrusion_rate_smoothing_external_perimeter_only",[m
[32m +        "reduce_infill_retraction",[m
[32m +        "filename_format",[m
[32m +        "retraction_minimum_travel",[m
[32m++=======[m
[32m+         "filament_spool_weight",[m
[32m+         "first_layer_acceleration",[m
[32m+         "first_layer_acceleration_over_raft",[m
[32m+         "first_layer_bed_temperature",[m
[32m+         "first_layer_speed_over_raft",[m
[32m+         "gcode_comments",[m
[32m+         "gcode_label_objects",[m
[32m+         "infill_acceleration",[m
[32m+         "layer_gcode",[m
[32m+         "min_fan_speed",[m
[32m+         "max_fan_speed",[m
[32m+         "max_print_height",[m
[32m+         "min_print_speed",[m
[32m+         "max_print_speed",[m
[32m+         "max_volumetric_speed",[m
[32m+ #ifdef HAS_PRESSURE_EQUALIZER[m
[32m+         "max_volumetric_extrusion_rate_slope_positive",[m
[32m+         "max_volumetric_extrusion_rate_slope_negative",[m
[32m+ #endif /* HAS_PRESSURE_EQUALIZER */[m
[32m+         "notes",[m
[32m+         "only_retract_when_crossing_perimeters",[m
[32m+         "output_filename_format",[m
[32m+         "perimeter_acceleration",[m
[32m+         "post_process",[m
[32m+         "printer_notes",[m
[32m+         "retract_before_travel",[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
          "retract_before_wipe",[m
[31m -        "retract_layer_change",[m
[31m -        "retract_length",[m
[32m +        "retract_when_changing_layer",[m
[32m +        "retraction_length",[m
          "retract_length_toolchange",[m
[31m -        "retract_lift",[m
[32m +        "z_hop",[m
[32m +        "travel_slope",[m
          "retract_lift_above",[m
[31m -        "retract_lift_below",[m
[32m +        "retract_lift_below", [m
[32m +        "retract_lift_enforce",[m
          "retract_restart_extra",[m
          "retract_restart_extra_toolchange",[m
[31m -        "retract_speed",[m
[31m -        "single_extruder_multi_material_priming",[m
[31m -        "slowdown_below_layer_time",[m
[31m -        "standby_temperature_delta",[m
[31m -        "start_gcode",[m
[31m -        "start_filament_gcode",[m
[31m -        "toolchange_gcode",[m
[31m -        "threads",[m
[32m +        "retraction_speed",[m
          "use_firmware_retraction",[m
[32m +        "slow_down_layer_time",[m
[32m +        "standby_temperature_delta",[m
[32m +        "preheat_time",[m
[32m +        "preheat_steps",[m
[32m +        "machine_start_gcode",[m
[32m +        "filament_start_gcode",[m
[32m +        "change_filament_gcode",[m
[32m +        "wipe",[m
[32m +        // BBS[m
[32m +        "wipe_distance",[m
[32m +        "curr_bed_type",[m
[32m +        "nozzle_volume",[m
[32m +        "nozzle_hrc",[m
[32m +        "required_nozzle_HRC",[m
[32m +        "upward_compatible_machine",[m
[32m +        "is_infill_first",[m
[32m +        // Orca[m
[32m +        "chamber_temperature",[m
[32m +        "thumbnails",[m
[32m +        "thumbnails_format",[m
[32m +        "seam_gap",[m
[32m +        "role_based_wipe_speed",[m
[32m +        "wipe_speed",[m
          "use_relative_e_distances",[m
[31m -        "use_volumetric_e",[m
[31m -        "variable_layer_height",[m
[31m -        "wipe"[m
[32m +        "accel_to_decel_enable",[m
[32m +        "accel_to_decel_factor",[m
[32m +        "wipe_on_loops",[m
[32m +        "gcode_comments",[m
[32m +        "gcode_label_objects", [m
[32m +        "exclude_object",[m
[32m +        "support_material_interface_fan_speed",[m
[32m +        "internal_bridge_fan_speed", // ORCA: Add support for separate internal bridge fan speed control[m
[32m +        "ironing_fan_speed",[m
[32m +        "single_extruder_multi_material_priming",[m
[32m +        "activate_air_filtration",[m
[32m +        "during_print_exhaust_fan_speed",[m
[32m +        "complete_print_exhaust_fan_speed",[m
[32m +        "activate_chamber_temp_control",[m
[32m +        "manual_filament_change",[m
[32m +        "disable_m73",[m
[32m +        "use_firmware_retraction",[m
[32m +        "enable_long_retraction_when_cut",[m
[32m +        "long_retractions_when_cut",[m
[32m +        "retraction_distances_when_cut",[m
[32m +        "filament_long_retractions_when_cut",[m
[32m +        "filament_retraction_distances_when_cut",[m
[32m +        "grab_length",[m
[32m +        "bed_temperature_formula",[m
[32m +        "filament_notes",[m
[32m +        "process_notes",[m
[32m +        "printer_notes"[m
      };[m
  [m
      static std::unordered_set<std::string> steps_ignore;[m
[1mdiff --cc src/libslic3r/PrintConfig.cpp[m
[1mindex 99fa8cad07,2917a9a19d..0000000000[m
[1m--- a/src/libslic3r/PrintConfig.cpp[m
[1m+++ b/src/libslic3r/PrintConfig.cpp[m
[36m@@@ -2873,50 -1139,239 +2873,261 @@@[m [mvoid PrintConfigDef::init_fff_params([m
      def->enum_labels.push_back(L("Hilbert Curve"));[m
      def->enum_labels.push_back(L("Archimedean Chords"));[m
      def->enum_labels.push_back(L("Octagram Spiral"));[m
[31m -    def->enum_labels.push_back(L("Adaptive Cubic"));[m
[31m -    def->enum_labels.push_back(L("Support Cubic"));[m
[31m -    def->set_default_value(new ConfigOptionEnum<InfillPattern>(ipStars));[m
[31m -[m
[31m -    def = this->add("first_layer_acceleration", coFloat);[m
[31m -    def->label = L("First layer");[m
[31m -    def->tooltip = L("This is the acceleration your printer will use for first layer. Set zero "[m
[31m -                   "to disable acceleration control for first layer.");[m
[31m -    def->sidetext = L("mm/s²");[m
[31m -    def->min = 0;[m
[31m -    def->mode = comExpert;[m
[31m -    def->set_default_value(new ConfigOptionFloat(0));[m
[32m +    def->set_default_value(new ConfigOptionEnum<InfillPattern>(ipCrossHatch));[m
[32m +[m
[32m +    def           = this->add("lateral_lattice_angle_1", coFloat);[m
[32m +    def->label    = L("Lateral lattice angle 1");[m
[32m +    def->category = L("Strength");[m
[32m +    def->tooltip  = L("The angle of the first set of Lateral lattice elements in the Z direction. Zero is vertical.");[m
[32m +    def->sidetext = u8"°";	// degrees, don't need translation[m
[32m +    def->min      = -75;[m
[32m +    def->max      = 75;[m
[32m +    def->mode     = comAdvanced;[m
[32m +    def->set_default_value(new ConfigOptionFloat(-45));[m
[32m +[m
[32m++<<<<<<< HEAD[m
[32m +    def           = this->add("lateral_lattice_angle_2", coFloat);[m
[32m +    def->label    = L("Lateral lattice angle 2");[m
[32m +    def->category = L("Strength");[m
[32m +    def->tooltip  = L("The angle of the second set of Lateral lattice elements in the Z direction. Zero is vertical.");[m
[32m +    def->sidetext = u8"°";	// degrees, don't need translation[m
[32m +    def->min      = -75;[m
[32m +    def->max      = 75;[m
[32m +    def->mode     = comAdvanced;[m
[32m +    def->set_default_value(new ConfigOptionFloat(45));[m
  [m
[32m +    def           = this->add("infill_overhang_angle", coFloat);[m
[32m +    def->label    = L("Infill overhang angle");[m
[32m +    def->category = L("Strength");[m
[32m +    def->tooltip  = L("The angle of the infill angled lines. 60° will result in a pure honeycomb.");[m
[32m +    def->sidetext = u8"°";	// degrees, don't need translation[m
[32m +    def->min      = 15;[m
[32m +    def->max      = 75;[m
[32m +    def->mode     = comAdvanced;[m
[32m +    def->set_default_value(new ConfigOptionFloat(60));[m
[32m++=======[m
[32m+     def = this->add("first_layer_acceleration_over_raft", coFloat);[m
[32m+     def->label = L("First object layer over raft interface");[m
[32m+     def->tooltip = L("This is the acceleration your printer will use for first layer of object above raft interface. Set zero "[m
[32m+                    "to disable acceleration control for first layer of object above raft interface.");[m
[32m+     def->sidetext = L("mm/s²");[m
[32m+     def->min = 0;[m
[32m+     def->mode = comExpert;[m
[32m+     def->set_default_value(new ConfigOptionFloat(0));[m
[32m+ [m
[32m+     def = this->add("first_layer_bed_temperature", coInts);[m
[32m+     def->label = L("First layer");[m
[32m+     def->full_label = L("First layer bed temperature");[m
[32m+     def->tooltip = L("Heated build plate temperature for the first layer. Set this to zero to disable "[m
[32m+                    "bed temperature control commands in the output.");[m
[32m+     def->sidetext = L("°C");[m
[32m+     def->max = 0;[m
[32m+     def->max = 300;[m
[32m+     def->set_default_value(new ConfigOptionInts { 0 });[m
[32m+ [m
[32m+     def = this->add("first_layer_extrusion_width", coFloatOrPercent);[m
[32m+     def->label = L("First layer");[m
[32m+     def->category = L("Extrusion Width");[m
[32m+     def->tooltip = L("Set this to a non-zero value to set a manual extrusion width for first layer. "[m
[32m+                    "You can use this to force fatter extrudates for better adhesion. If expressed "[m
[32m+                    "as percentage (for example 120%) it will be computed over first layer height. "[m
[32m+                    "If set to zero, it will use the default extrusion width.");[m
[32m+     def->sidetext = L("mm or %");[m
[32m+     def->ratio_over = "first_layer_height";[m
[32m+     def->min = 0;[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionFloatOrPercent(200, true));[m
[32m+ [m
[32m+     def = this->add("first_layer_height", coFloatOrPercent);[m
[32m+     def->label = L("First layer height");[m
[32m+     def->category = L("Layers and Perimeters");[m
[32m+     def->tooltip = L("When printing with very low layer heights, you might still want to print a thicker "[m
[32m+                    "bottom layer to improve adhesion and tolerance for non perfect build plates.");[m
[32m+     def->sidetext = L("mm");[m
[32m+     def->ratio_over = "layer_height";[m
[32m+     def->set_default_value(new ConfigOptionFloatOrPercent(0.35, false));[m
[32m+ [m
[32m+     def = this->add("first_layer_speed", coFloatOrPercent);[m
[32m+     def->label = L("First layer speed");[m
[32m+     def->tooltip = L("If expressed as absolute value in mm/s, this speed will be applied to all the print moves "[m
[32m+                    "of the first layer, regardless of their type. If expressed as a percentage "[m
[32m+                    "(for example: 40%) it will scale the default speeds.");[m
[32m+     def->sidetext = L("mm/s or %");[m
[32m+     def->min = 0;[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionFloatOrPercent(30, false));[m
[32m+ [m
[32m+     def = this->add("first_layer_speed_over_raft", coFloatOrPercent);[m
[32m+     def->label = L("Speed of object first layer over raft interface");[m
[32m+     def->tooltip = L("If expressed as absolute value in mm/s, this speed will be applied to all the print moves "[m
[32m+                    "of the first object layer above raft interface, regardless of their type. If expressed as a percentage "[m
[32m+                    "(for example: 40%) it will scale the default speeds.");[m
[32m+     def->sidetext = L("mm/s or %");[m
[32m+     def->min = 0;[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionFloatOrPercent(30, false));[m
[32m+ [m
[32m+     def = this->add("first_layer_temperature", coInts);[m
[32m+     def->label = L("First layer");[m
[32m+     def->full_label = L("First layer nozzle temperature");[m
[32m+     def->tooltip = L("Nozzle temperature for the first layer. If you want to control temperature manually "[m
[32m+                      "during print, set this to zero to disable temperature control commands in the output G-code.");[m
[32m+     def->sidetext = L("°C");[m
[32m+     def->min = 0;[m
[32m+     def->max = max_temp;[m
[32m+     def->set_default_value(new ConfigOptionInts { 200 });[m
[32m+ [m
[32m+     def = this->add("full_fan_speed_layer", coInts);[m
[32m+     def->label = L("Full fan speed at layer");[m
[32m+     def->tooltip = L("Fan speed will be ramped up linearly from zero at layer \"disable_fan_first_layers\" "[m
[32m+                    "to maximum at layer \"full_fan_speed_layer\". "[m
[32m+                    "\"full_fan_speed_layer\" will be ignored if lower than \"disable_fan_first_layers\", in which case "[m
[32m+                    "the fan will be running at maximum allowed speed at layer \"disable_fan_first_layers\" + 1.");[m
[32m+     def->min = 0;[m
[32m+     def->max = 1000;[m
[32m+     def->mode = comExpert;[m
[32m+     def->set_default_value(new ConfigOptionInts { 0 });[m
[32m+ [m
[32m+     def = this->add("fuzzy_skin", coEnum);[m
[32m+     def->label = L("Fuzzy Skin");[m
[32m+     def->category = L("Fuzzy Skin");[m
[32m+     def->tooltip = L("Fuzzy skin type.");[m
[32m+ [m
[32m+     def->enum_keys_map = &ConfigOptionEnum<FuzzySkinType>::get_enum_values();[m
[32m+     def->enum_values.push_back("none");[m
[32m+     def->enum_values.push_back("external");[m
[32m+     def->enum_values.push_back("all");[m
[32m+     def->enum_labels.push_back(L("None"));[m
[32m+     def->enum_labels.push_back(L("External perimeters"));[m
[32m+     def->enum_labels.push_back(L("All perimeters"));[m
[32m+     def->mode = comSimple;[m
[32m+     def->set_default_value(new ConfigOptionEnum<FuzzySkinType>(FuzzySkinType::None));[m
[32m+ [m
[32m+     def = this->add("fuzzy_skin_thickness", coFloat);[m
[32m+     def->label = L("Fuzzy skin thickness");[m
[32m+     def->category = L("Fuzzy Skin");[m
[32m+     def->tooltip = "";[m
[32m+     def->sidetext = L("mm");[m
[32m+     def->min = 0;[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionFloat(0.3));[m
[32m+ [m
[32m+     def = this->add("fuzzy_skin_point_dist", coFloat);[m
[32m+     def->label = L("Fuzzy skin point distance");[m
[32m+     def->category = L("Fuzzy Skin");[m
[32m+     def->tooltip = "";[m
[32m+     def->sidetext = L("mm");[m
[32m+     def->min = 0;[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionFloat(0.8));[m
[32m+ [m
[32m+     def = this->add("gap_fill_enabled", coBool);[m
[32m+     def->label = L("Fill gaps");[m
[32m+     def->category = L("Layers and Perimeters");[m
[32m+     def->tooltip = L("Enables filling of gaps between perimeters and between the inner most perimeters and infill.");[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionBool(true));[m
[32m+ [m
[32m+     def = this->add("gap_fill_speed", coFloat);[m
[32m+     def->label = L("Gap fill");[m
[32m+     def->category = L("Speed");[m
[32m+     def->tooltip = L("Speed for filling small gaps using short zigzag moves. Keep this reasonably low "[m
[32m+                    "to avoid too much shaking and resonance issues. Set zero to disable gaps filling.");[m
[32m+     def->sidetext = L("mm/s");[m
[32m+     def->min = 0;[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionFloat(20));[m
[32m+ [m
[32m+     def = this->add("gcode_comments", coBool);[m
[32m+     def->label = L("Verbose G-code");[m
[32m+     def->tooltip = L("Enable this to get a commented G-code file, with each line explained by a descriptive text. "[m
[32m+                    "If you print from SD card, the additional weight of the file could make your firmware "[m
[32m+                    "slow down.");[m
[32m+     def->mode = comExpert;[m
[32m+     def->set_default_value(new ConfigOptionBool(0));[m
[32m+ [m
[32m+     def = this->add("gcode_flavor", coEnum);[m
[32m+     def->label = L("G-code flavor");[m
[32m+     def->tooltip = L("Some G/M-code commands, including temperature control and others, are not universal. "[m
[32m+                    "Set this option to your printer's firmware to get a compatible output. "[m
[32m+                    "The \"No extrusion\" flavor prevents PrusaSlicer from exporting any extrusion value at all.");[m
[32m+     def->enum_keys_map = &ConfigOptionEnum<GCodeFlavor>::get_enum_values();[m
[32m+     def->enum_values.push_back("reprap");[m
[32m+     def->enum_values.push_back("reprapfirmware");[m
[32m+     def->enum_values.push_back("repetier");[m
[32m+     def->enum_values.push_back("teacup");[m
[32m+     def->enum_values.push_back("makerware");[m
[32m+     def->enum_values.push_back("marlin");[m
[32m+     def->enum_values.push_back("marlin2");[m
[32m+     def->enum_values.push_back("sailfish");[m
[32m+     def->enum_values.push_back("mach3");[m
[32m+     def->enum_values.push_back("machinekit");[m
[32m+     def->enum_values.push_back("smoothie");[m
[32m+     def->enum_values.push_back("no-extrusion");[m
[32m+     def->enum_labels.push_back("RepRap/Sprinter");[m
[32m+     def->enum_labels.push_back("RepRapFirmware");[m
[32m+     def->enum_labels.push_back("Repetier");[m
[32m+     def->enum_labels.push_back("Teacup");[m
[32m+     def->enum_labels.push_back("MakerWare (MakerBot)");[m
[32m+     def->enum_labels.push_back("Marlin (legacy)");[m
[32m+     def->enum_labels.push_back("Marlin 2");[m
[32m+     def->enum_labels.push_back("Sailfish (MakerBot)");[m
[32m+     def->enum_labels.push_back("Mach3/LinuxCNC");[m
[32m+     def->enum_labels.push_back("Machinekit");[m
[32m+     def->enum_labels.push_back("Smoothie");[m
[32m+     def->enum_labels.push_back(L("No extrusion"));[m
[32m+     def->mode = comExpert;[m
[32m+     def->set_default_value(new ConfigOptionEnum<GCodeFlavor>(gcfRepRapSprinter));[m
[32m+ [m
[32m+     def = this->add("gcode_label_objects", coBool);[m
[32m+     def->label = L("Label objects");[m
[32m+     def->tooltip = L("Enable this to add comments into the G-Code labeling print moves with what object they belong to,"[m
[32m+                    " which is useful for the Octoprint CancelObject plugin. This settings is NOT compatible with "[m
[32m+                    "Single Extruder Multi Material setup and Wipe into Object / Wipe into Infill.");[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionBool(0));[m
[32m+ [m
[32m+     def = this->add("high_current_on_filament_swap", coBool);[m
[32m+     def->label = L("High extruder current on filament swap");[m
[32m+     def->tooltip = L("It may be beneficial to increase the extruder motor current during the filament exchange"[m
[32m+                    " sequence to allow for rapid ramming feed rates and to overcome resistance when loading"[m
[32m+                    " a filament with an ugly shaped tip.");[m
[32m+     def->mode = comExpert;[m
[32m+     def->set_default_value(new ConfigOptionBool(0));[m
[32m+ [m
[32m+     def = this->add("infill_acceleration", coFloat);[m
[32m+     def->label = L("Infill");[m
[32m+     def->tooltip = L("This is the acceleration your printer will use for infill. Set zero to disable "[m
[32m+                    "acceleration control for infill.");[m
[32m+     def->sidetext = L("mm/s²");[m
[32m+     def->min = 0;[m
[32m+     def->mode = comExpert;[m
[32m+     def->set_default_value(new ConfigOptionFloat(0));[m
[32m+ [m
[32m+     def = this->add("infill_every_layers", coInt);[m
[32m+     def->label = L("Combine infill every");[m
[32m+     def->category = L("Infill");[m
[32m+     def->tooltip = L("This feature allows to combine infill and speed up your print by extruding thicker "[m
[32m+                    "infill layers while preserving thin perimeters, thus accuracy.");[m
[32m+     def->sidetext = L("layers");[m
[32m+     def->full_label = L("Combine infill every n layers");[m
[32m+     def->min = 1;[m
[32m+     def->mode = comAdvanced;[m
[32m+     def->set_default_value(new ConfigOptionInt(1));[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
  [m
      auto def_infill_anchor_min = def = this->add("infill_anchor", coFloatOrPercent);[m
[31m -    def->label = L("Length of the infill anchor");[m
[31m -    def->category = L("Advanced");[m
[32m +    def->label = L("Sparse infill anchor length");[m
[32m +    def->category = L("Strength");[m
      def->tooltip = L("Connect an infill line to an internal perimeter with a short segment of an additional perimeter. "[m
                       "If expressed as percentage (example: 15%) it is calculated over infill extrusion width. "[m
[31m -                     "PrusaSlicer tries to connect two close infill lines to a short perimeter segment. If no such perimeter segment "[m
[32m +                     "Orca Slicer tries to connect two close infill lines to a short perimeter segment. If no such perimeter segment "[m
                       "shorter than infill_anchor_max is found, the infill line is connected to a perimeter segment at just one side "[m
[31m -                     "and the length of the perimeter segment taken is limited to this parameter, but no longer than anchor_length_max. "[m
[32m +                     "and the length of the perimeter segment taken is limited to this parameter, but no longer than anchor_length_max.\n"[m
                       "Set this parameter to zero to disable anchoring perimeters connected to a single infill line.");[m
      def->sidetext = L("mm or %");[m
[31m -    def->ratio_over = "infill_extrusion_width";[m
[32m +    def->ratio_over = "sparse_infill_line_width";[m
[32m +    def->max_literal = 1000;[m
      def->gui_type = ConfigOptionDef::GUIType::f_enum_open;[m
      def->enum_values.push_back("0");[m
      def->enum_values.push_back("1");[m
[1mdiff --cc src/libslic3r/PrintConfig.hpp[m
[1mindex 991ab5c815,d7409d12ce..0000000000[m
[1m--- a/src/libslic3r/PrintConfig.hpp[m
[1m+++ b/src/libslic3r/PrintConfig.hpp[m
[36m@@@ -898,18 -449,16 +898,25 @@@[m [mprotected: [m
  PRINT_CONFIG_CLASS_DEFINE([m
      PrintObjectConfig,[m
  [m
[31m -    ((ConfigOptionFloat,               brim_separation))[m
[32m +    ((ConfigOptionFloat,               brim_object_gap))[m
[32m +    ((ConfigOptionBool,                brim_use_efc_outline))[m
      ((ConfigOptionEnum<BrimType>,      brim_type))[m
      ((ConfigOptionFloat,               brim_width))[m
[31m -    ((ConfigOptionBool,                clip_multipart_objects))[m
[31m -    ((ConfigOptionBool,                dont_support_bridges))[m
[32m +    ((ConfigOptionFloat,               brim_ears_detection_length))[m
[32m +    ((ConfigOptionFloat,               brim_ears_max_angle))[m
[32m +    ((ConfigOptionFloat,               skirt_start_angle))[m
[32m +    ((ConfigOptionBool,                bridge_no_support))[m
      ((ConfigOptionFloat,               elefant_foot_compensation))[m
[32m++<<<<<<< HEAD[m
[32m +    ((ConfigOptionInt,                 elefant_foot_compensation_layers))[m
[32m +    ((ConfigOptionFloat,               max_bridge_length))[m
[32m +    ((ConfigOptionFloatOrPercent,      line_width))[m
[32m++=======[m
[32m+     ((ConfigOptionFloatOrPercent,      extrusion_width))[m
[32m+     ((ConfigOptionFloat,               first_layer_acceleration_over_raft))[m
[32m+     ((ConfigOptionFloatOrPercent,      first_layer_speed_over_raft))[m
[32m+     ((ConfigOptionBool,                infill_only_where_needed))[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
      // Force the generation of solid shells between adjacent materials/volumes.[m
      ((ConfigOptionBool,                interface_shells))[m
      ((ConfigOptionFloat,               layer_height))[m
[1mdiff --cc src/slic3r/GUI/ConfigManipulation.cpp[m
[1mindex df92e35594,d4920d8364..0000000000[m
[1m--- a/src/slic3r/GUI/ConfigManipulation.cpp[m
[1m+++ b/src/slic3r/GUI/ConfigManipulation.cpp[m
[36m@@@ -497,474 -227,112 +497,480 @@@[m [mvoid ConfigManipulation::update_print_f[m
              }[m
          }[m
      }[m
[32m +[m
[32m +    if (config->opt_enum<SeamScarfType>("seam_slope_type") != SeamScarfType::None &&[m
[32m +        config->get_abs_value("seam_slope_start_height") >= layer_height) {[m
[32m +        const wxString     msg_text = _(L("seam_slope_start_height need to be smaller than layer_height.\nReset to 0."));[m
[32m +        MessageDialog      dialog(m_msg_dlg_parent, msg_text, "", wxICON_WARNING | wxOK);[m
[32m +        DynamicPrintConfig new_conf = *config;[m
[32m +        is_msg_dlg_already_exist    = true;[m
[32m +        dialog.ShowModal();[m
[32m +        new_conf.set_key_value("seam_slope_start_height", new ConfigOptionFloatOrPercent(0, false));[m
[32m +        apply(config, &new_conf);[m
[32m +        is_msg_dlg_already_exist = false;[m
[32m +    }[m
[32m +[m
[32m +    // layer_height shouldn't be equal to zero[m
[32m +    float skin_depth = config->opt_float("skin_infill_depth");[m
[32m +    if (config->opt_float("infill_lock_depth") > skin_depth) {[m
[32m +        const wxString     msg_text = _(L("Lock depth should smaller than skin depth.\nReset to 50% of skin depth."));[m
[32m +        MessageDialog      dialog(m_msg_dlg_parent, msg_text, "", wxICON_WARNING | wxOK);[m
[32m +        DynamicPrintConfig new_conf = *config;[m
[32m +        is_msg_dlg_already_exist    = true;[m
[32m +        dialog.ShowModal();[m
[32m +        new_conf.set_key_value("infill_lock_depth", new ConfigOptionFloat(skin_depth / 2));[m
[32m +        apply(config, &new_conf);[m
[32m +        is_msg_dlg_already_exist = false;[m
[32m +    }[m
[32m +    [m
[32m +    bool have_arachne = config->opt_enum<PerimeterGeneratorType>("wall_generator") == PerimeterGeneratorType::Arachne;[m
[32m +    if (config->opt_enum<FuzzySkinMode>("fuzzy_skin_mode") != FuzzySkinMode::Displacement && !have_arachne) {[m
[32m +        wxString msg_text = _(L("Both [Extrusion] and [Combined] modes of Fuzzy Skin require the Arachne Wall Generator to be enabled."));[m
[32m +        msg_text += "\n\n" + _(L("Change these settings automatically?\n"[m
[32m +                                    "Yes - Enable Arachne Wall Generator\n"[m
[32m +                                    "No  - Disable Arachne Wall Generator and set [Displacement] mode of the Fuzzy Skin"));[m
[32m +        MessageDialog dialog(m_msg_dlg_parent, msg_text, "", wxICON_WARNING | wxYES | wxNO);[m
[32m +        DynamicPrintConfig new_conf = *config;[m
[32m +        is_msg_dlg_already_exist = true;[m
[32m +        auto answer = dialog.ShowModal();[m
[32m +        if (answer == wxID_YES)[m
[32m +            new_conf.set_key_value("wall_generator", new ConfigOptionEnum<PerimeterGeneratorType>(PerimeterGeneratorType::Arachne));[m
[32m +        else [m
[32m +            new_conf.set_key_value("fuzzy_skin_mode", new ConfigOptionEnum<FuzzySkinMode>(FuzzySkinMode::Displacement));[m
[32m +        apply(config, &new_conf);[m
[32m +        is_msg_dlg_already_exist = false;[m
[32m +    }[m
[32m +}[m
[32m +[m
[32m +void ConfigManipulation::apply_null_fff_config(DynamicPrintConfig *config, std::vector<std::string> const &keys, std::map<ObjectBase *, ModelConfig *> const &configs)[m
[32m +{[m
[32m +    for (auto &k : keys) {[m
[32m +        if (/*k == "adaptive_layer_height" || */ k == "independent_support_layer_height" || k == "enable_support" ||[m
[32m +            k == "detect_thin_wall" || k == "tree_support_adaptive_layer_height")[m
[32m +            config->set_key_value(k, new ConfigOptionBool(true));[m
[32m +        else if (k == "wall_loops")[m
[32m +            config->set_key_value(k, new ConfigOptionInt(0));[m
[32m +        else if (k == "top_shell_layers" || k == "enforce_support_layers")[m
[32m +            config->set_key_value(k, new ConfigOptionInt(1));[m
[32m +        else if (k == "sparse_infill_density") {[m
[32m +            double v = config->option<ConfigOptionPercent>(k)->value;[m
[32m +            for (auto &c : configs) {[m
[32m +                auto o = c.second->get().option<ConfigOptionPercent>(k);[m
[32m +                if (o && o->value > v) v = o->value;[m
[32m +            }[m
[32m +            config->set_key_value(k, new ConfigOptionPercent(v)); // sparse_infill_pattern[m
[32m +        }[m
[32m +        else if (k == "detect_overhang_wall")[m
[32m +            config->set_key_value(k, new ConfigOptionBool(false));[m
[32m +        else if (k == "sparse_infill_pattern")[m
[32m +            config->set_key_value(k, new ConfigOptionEnum<InfillPattern>(ipGrid));[m
[32m +    }[m
  }[m
  [m
[31m -void ConfigManipulation::toggle_print_fff_options(DynamicPrintConfig* config)[m
[32m +void ConfigManipulation::toggle_print_fff_options(DynamicPrintConfig *config, const bool is_global_config)[m
  {[m
[31m -    bool have_perimeters = config->opt_int("perimeters") > 0;[m
[31m -    for (auto el : { "extra_perimeters", "ensure_vertical_shell_thickness", "thin_walls", "overhangs",[m
[31m -                    "seam_position", "external_perimeters_first", "external_perimeter_extrusion_width",[m
[31m -                    "perimeter_speed", "small_perimeter_speed", "external_perimeter_speed" })[m
[32m +    PresetBundle *preset_bundle  = wxGetApp().preset_bundle;[m
[32m +[m
[32m +    auto gcflavor = preset_bundle->printers.get_edited_preset().config.option<ConfigOptionEnum<GCodeFlavor>>("gcode_flavor")->value;[m
[32m +[m
[32m +    bool have_volumetric_extrusion_rate_slope = config->option<ConfigOptionFloat>("max_volumetric_extrusion_rate_slope")->value > 0;[m
[32m +    float have_volumetric_extrusion_rate_slope_segment_length = config->option<ConfigOptionFloat>("max_volumetric_extrusion_rate_slope_segment_length")->value;[m
[32m +    toggle_field("enable_arc_fitting", !have_volumetric_extrusion_rate_slope);[m
[32m +    toggle_line("max_volumetric_extrusion_rate_slope_segment_length", have_volumetric_extrusion_rate_slope);[m
[32m +    toggle_line("extrusion_rate_smoothing_external_perimeter_only", have_volumetric_extrusion_rate_slope);[m
[32m +    if(have_volumetric_extrusion_rate_slope) config->set_key_value("enable_arc_fitting", new ConfigOptionBool(false));[m
[32m +    if(have_volumetric_extrusion_rate_slope_segment_length < 0.5) {[m
[32m +        DynamicPrintConfig new_conf = *config;[m
[32m +        new_conf.set_key_value("max_volumetric_extrusion_rate_slope_segment_length", new ConfigOptionFloat(1));[m
[32m +        apply(config, &new_conf);[m
[32m +    }[m
[32m +[m
[32m +    bool have_perimeters = config->opt_int("wall_loops") > 0;[m
[32m +    for (auto el : { "extra_perimeters_on_overhangs", "ensure_vertical_shell_thickness", "detect_thin_wall", "detect_overhang_wall",[m
[32m +        "seam_position", "staggered_inner_seams", "wall_sequence", "outer_wall_line_width",[m
[32m +        "inner_wall_speed", "outer_wall_speed", "small_perimeter_speed", "small_perimeter_threshold" })[m
          toggle_field(el, have_perimeters);[m
  [m
[31m -    bool have_infill = config->option<ConfigOptionPercent>("fill_density")->value > 0;[m
[31m -    // infill_extruder uses the same logic as in Print::extruders()[m
[31m -    for (auto el : { "fill_pattern", "infill_every_layers", "infill_only_where_needed",[m
[31m -                    "solid_infill_every_layers", "solid_infill_below_area", "infill_extruder", "infill_anchor_max" })[m
[31m -        toggle_field(el, have_infill);[m
[31m -    // Only allow configuration of open anchors if the anchoring is enabled.[m
[31m -    bool has_infill_anchors = have_infill && config->option<ConfigOptionFloatOrPercent>("infill_anchor_max")->value > 0;[m
[31m -    toggle_field("infill_anchor", has_infill_anchors);[m
[31m -[m
[31m -    bool has_spiral_vase         = config->opt_bool("spiral_vase");[m
[31m -    bool has_top_solid_infill 	 = config->opt_int("top_solid_layers") > 0;[m
[31m -    bool has_bottom_solid_infill = config->opt_int("bottom_solid_layers") > 0;[m
[31m -    bool has_solid_infill 		 = has_top_solid_infill || has_bottom_solid_infill;[m
[31m -    // solid_infill_extruder uses the same logic as in Print::extruders()[m
[31m -    for (auto el : { "top_fill_pattern", "bottom_fill_pattern", "infill_first", "solid_infill_extruder",[m
[31m -                    "solid_infill_extrusion_width", "solid_infill_speed" })[m
[31m -        toggle_field(el, has_solid_infill);[m
[31m -[m
[31m -    for (auto el : { "fill_angle", "bridge_angle", "infill_extrusion_width",[m
[31m -                    "infill_speed", "bridge_speed" })[m
[32m +    bool have_infill = config->option<ConfigOptionPercent>("sparse_infill_density")->value > 0;[m
[32m +    // sparse_infill_filament uses the same logic as in Print::extruders()[m
[32m +    for (auto el : { "sparse_infill_pattern", "infill_combination", "fill_multiline","infill_direction",[m
[32m +        "minimum_sparse_infill_area", "sparse_infill_filament", "infill_anchor", "infill_anchor_max","infill_shift_step","sparse_infill_rotate_template","symmetric_infill_y_axis"})[m
[32m +        toggle_line(el, have_infill);[m
[32m +[m
[32m +    bool have_combined_infill = config->opt_bool("infill_combination") && have_infill;[m
[32m +    toggle_line("infill_combination_max_layer_height", have_combined_infill);[m
[32m +[m
[32m +    // Infill patterns that support multiline infill.[m
[32m +    InfillPattern pattern = config->opt_enum<InfillPattern>("sparse_infill_pattern");[m
[32m +    bool          have_multiline_infill_pattern = pattern == ipGyroid || pattern == ipGrid || pattern == ipRectilinear || pattern == ipTpmsD || pattern == ipTpmsFK || pattern == ipCrossHatch || pattern == ipHoneycomb || pattern == ipLateralLattice || pattern == ipLateralHoneycomb || pattern == ipConcentric ||[m
[32m +                                                  pattern == ipCubic || pattern == ipStars || pattern == ipAlignedRectilinear || pattern == ipLightning || pattern == ip3DHoneycomb || pattern == ipAdaptiveCubic || pattern == ipSupportCubic|| pattern == ipTriangles || pattern == ipQuarterCubic|| pattern == ipArchimedeanChords || pattern == ipHilbertCurve || pattern == ipOctagramSpiral;[m
[32m +[m
[32m +    // If there is infill, enable/disable fill_multiline according to whether the pattern supports multiline infill.[m
[32m +    if (have_infill) {[m
[32m +        toggle_field("fill_multiline", have_multiline_infill_pattern);[m
[32m +        // If the infill pattern does not support multiline fill_multiline is changed to 1.[m
[32m +        // Necessary when the pattern contains params.multiline (for example, triangles because they belong to the rectilinear class)[m
[32m +        if (!have_multiline_infill_pattern) {[m
[32m +            DynamicPrintConfig new_conf = *config;[m
[32m +            new_conf.set_key_value("fill_multiline", new ConfigOptionInt(1));[m
[32m +            apply(config, &new_conf);[m
[32m +        }[m
[32m +        // Hide infill anchor max if sparse_infill_pattern is not line or if sparse_infill_pattern is line but infill_anchor_max is 0.[m
[32m +        bool infill_anchor = config->opt_enum<InfillPattern>("sparse_infill_pattern") != ipLine;[m
[32m +        toggle_field("infill_anchor_max", infill_anchor);[m
[32m +[m
[32m +        // Only allow configuration of open anchors if the anchoring is enabled.[m
[32m +        bool has_infill_anchors = infill_anchor && config->option<ConfigOptionFloatOrPercent>("infill_anchor_max")->value > 0;[m
[32m +        toggle_field("infill_anchor", has_infill_anchors);[m
[32m +    }[m
[32m +[m
[32m +    //cross zag[m
[32m +    bool is_cross_zag = config->option<ConfigOptionEnum<InfillPattern>>("sparse_infill_pattern")->value == InfillPattern::ipCrossZag;[m
[32m +    bool is_locked_zig = config->option<ConfigOptionEnum<InfillPattern>>("sparse_infill_pattern")->value == InfillPattern::ipLockedZag;[m
[32m +[m
[32m +    toggle_line("infill_shift_step", is_cross_zag || is_locked_zig);[m
[32m +    [m
[32m +    for (auto el : { "skeleton_infill_density", "skin_infill_density", "infill_lock_depth", "skin_infill_depth","skin_infill_line_width", "skeleton_infill_line_width" })[m
[32m +        toggle_line(el, is_locked_zig);[m
[32m +[m
[32m +    bool is_zig_zag = config->option<ConfigOptionEnum<InfillPattern>>("sparse_infill_pattern")->value == InfillPattern::ipZigZag;[m
[32m +[m
[32m +    toggle_line("symmetric_infill_y_axis", is_zig_zag || is_cross_zag || is_locked_zig);[m
[32m +[m
[32m +    bool has_spiral_vase         = config->opt_bool("spiral_mode");[m
[32m +    toggle_line("spiral_mode_smooth", has_spiral_vase);[m
[32m +    toggle_line("spiral_mode_max_xy_smoothing", has_spiral_vase && config->opt_bool("spiral_mode_smooth"));[m
[32m +    toggle_line("spiral_starting_flow_ratio", has_spiral_vase);[m
[32m +    toggle_line("spiral_finishing_flow_ratio", has_spiral_vase);[m
[32m +    bool has_top_shell    = config->opt_int("top_shell_layers") > 0 || (has_spiral_vase && config->opt_int("bottom_shell_layers") > 1);[m
[32m +    bool has_bottom_shell = config->opt_int("bottom_shell_layers") > 0;[m
[32m +    bool has_solid_infill = has_top_shell || has_bottom_shell;[m
[32m +    toggle_field("top_surface_pattern", has_top_shell);[m
[32m +    toggle_field("bottom_surface_pattern", has_bottom_shell);[m
[32m +    toggle_field("top_surface_density", has_top_shell);[m
[32m +    toggle_field("bottom_surface_density", has_bottom_shell);[m
[32m +[m
[32m +    for (auto el : { "infill_direction", "sparse_infill_line_width", "gap_fill_target","filter_out_gap_fill","infill_wall_overlap",[m
[32m +        "sparse_infill_speed", "bridge_speed", "internal_bridge_speed", "bridge_angle", "internal_bridge_angle",[m
[32m +        "solid_infill_direction", "solid_infill_rotate_template", "internal_solid_infill_pattern", "solid_infill_filament",[m
[32m +        })[m
          toggle_field(el, have_infill || has_solid_infill);[m
  [m
[31m -    toggle_field("top_solid_min_thickness", ! has_spiral_vase && has_top_solid_infill);[m
[31m -    toggle_field("bottom_solid_min_thickness", ! has_spiral_vase && has_bottom_solid_infill);[m
[32m +    toggle_field("top_shell_thickness", ! has_spiral_vase && has_top_shell);[m
[32m +    toggle_field("bottom_shell_thickness", ! has_spiral_vase && has_bottom_shell);[m
  [m
      // Gap fill is newly allowed in between perimeter lines even for empty infill (see GH #1476).[m
[31m -    toggle_field("gap_fill_speed", have_perimeters);[m
[32m +    toggle_field("gap_infill_speed", have_perimeters);[m
  [m
[31m -    for (auto el : { "top_infill_extrusion_width", "top_solid_infill_speed" })[m
[31m -        toggle_field(el, has_top_solid_infill || (has_spiral_vase && has_bottom_solid_infill));[m
[32m +    for (auto el : { "top_surface_line_width", "top_surface_speed" })[m
[32m +        toggle_field(el, has_top_shell);[m
  [m
      bool have_default_acceleration = config->opt_float("default_acceleration") > 0;[m
[31m -    for (auto el : { "perimeter_acceleration", "infill_acceleration",[m
[31m -                    "bridge_acceleration", "first_layer_acceleration" })[m
[32m +[m
[32m +    for (auto el : {"outer_wall_acceleration", "inner_wall_acceleration", "initial_layer_acceleration",[m
[32m +        "top_surface_acceleration", "travel_acceleration", "bridge_acceleration", "sparse_infill_acceleration", "internal_solid_infill_acceleration"})[m
          toggle_field(el, have_default_acceleration);[m
  [m
[31m -    bool have_skirt = config->opt_int("skirts") > 0;[m
[32m +    bool machine_supports_junction_deviation = false;[m
[32m +    if (gcflavor == gcfMarlinFirmware) {[m
[32m +        if (const auto *machine_jd = preset_bundle->printers.get_edited_preset().config.option<ConfigOptionFloats>("machine_max_junction_deviation")) {[m
[32m +            machine_supports_junction_deviation = !machine_jd->values.empty() && machine_jd->values.front() > 0.0;[m
[32m +        }[m
[32m +    }[m
[32m +    toggle_line("default_junction_deviation", gcflavor == gcfMarlinFirmware);[m
[32m +    if (machine_supports_junction_deviation) {[m
[32m +        toggle_field("default_junction_deviation", true);[m
[32m +        toggle_field("default_jerk", false);[m
[32m +        for (auto el : { "outer_wall_jerk", "inner_wall_jerk", "initial_layer_jerk", "top_surface_jerk", "travel_jerk", "infill_jerk"})[m
[32m +        toggle_line(el, false);[m
[32m +    } else {[m
[32m +        toggle_field("default_junction_deviation", false);[m
[32m +        toggle_field("default_jerk", true);[m
[32m +        bool have_default_jerk = config->has("default_jerk") && config->opt_float("default_jerk") > 0;[m
[32m +        for (auto el : { "outer_wall_jerk", "inner_wall_jerk", "initial_layer_jerk", "top_surface_jerk", "travel_jerk", "infill_jerk"}) {[m
[32m +            toggle_line(el, true);[m
[32m +            toggle_field(el, have_default_jerk);[m
[32m +        }[m
[32m +    }[m
[32m +[m
[32m +    bool have_skirt = config->opt_int("skirt_loops") > 0;[m
      toggle_field("skirt_height", have_skirt && config->opt_enum<DraftShield>("draft_shield") != dsEnabled);[m
[31m -    for (auto el : { "skirt_distance", "draft_shield", "min_skirt_length" })[m
[32m +    toggle_line("single_loop_draft_shield", have_skirt); // ORCA: Display one wall if skirt enabled[m
[32m +    for (auto el : {"skirt_type", "min_skirt_length", "skirt_distance", "skirt_start_angle", "skirt_speed", "draft_shield"})[m
          toggle_field(el, have_skirt);[m
  [m
[31m -    bool have_brim = config->opt_enum<BrimType>("brim_type") != btNoBrim;[m
[31m -    for (auto el : { "brim_width", "brim_separation" })[m
[31m -        toggle_field(el, have_brim);[m
[31m -    // perimeter_extruder uses the same logic as in Print::extruders()[m
[31m -    toggle_field("perimeter_extruder", have_perimeters || have_brim);[m
[32m +    bool have_brim = (config->opt_enum<BrimType>("brim_type") != btNoBrim);[m
[32m +    toggle_field("brim_object_gap", have_brim);[m
[32m +    toggle_field("brim_use_efc_outline", have_brim);[m
[32m +    toggle_field("combine_brims", have_brim);[m
[32m +    bool have_brim_width = (config->opt_enum<BrimType>("brim_type") != btNoBrim) && config->opt_enum<BrimType>("brim_type") != btAutoBrim &&[m
[32m +                           config->opt_enum<BrimType>("brim_type") != btPainted;[m
[32m +    toggle_field("brim_width", have_brim_width);[m
[32m +    // wall_filament uses the same logic as in Print::extruders()[m
[32m +    toggle_field("wall_filament", have_perimeters || have_brim);[m
[32m +[m
[32m +    bool have_brim_ear = (config->opt_enum<BrimType>("brim_type") == btEar);[m
[32m +    const auto brim_width = config->opt_float("brim_width");[m
[32m +    // disable brim_ears_max_angle and brim_ears_detection_length if brim_width is 0[m
[32m +    toggle_field("brim_ears_max_angle", brim_width > 0.0f);[m
[32m +    toggle_field("brim_ears_detection_length", brim_width > 0.0f);[m
[32m +    // hide brim_ears_max_angle and brim_ears_detection_length if brim_ear is not selected[m
[32m +    toggle_line("brim_ears_max_angle", have_brim_ear);[m
[32m +    toggle_line("brim_ears_detection_length", have_brim_ear);[m
[32m +[m
[32m +    // Hide Elephant foot compensation layers if elefant_foot_compensation is not enabled[m
[32m +    toggle_line("elefant_foot_compensation_layers", config->opt_float("elefant_foot_compensation") > 0);[m
  [m
      bool have_raft = config->opt_int("raft_layers") > 0;[m
[31m -    bool have_support_material = config->opt_bool("support_material") || have_raft;[m
[31m -    bool have_support_material_auto = have_support_material && config->opt_bool("support_material_auto");[m
[31m -    bool have_support_interface = config->opt_int("support_material_interface_layers") > 0;[m
[31m -    bool have_support_soluble = have_support_material && config->opt_float("support_material_contact_distance") == 0;[m
[31m -    auto support_material_style = config->opt_enum<SupportMaterialStyle>("support_material_style");[m
[31m -    for (auto el : { "support_material_style", "support_material_pattern", "support_material_with_sheath",[m
[31m -                    "support_material_spacing", "support_material_angle", [m
[31m -                    "support_material_interface_pattern", "support_material_interface_layers",[m
[31m -                    "dont_support_bridges", "support_material_extrusion_width", "support_material_contact_distance",[m
[31m -                    "support_material_xy_spacing" })[m
[32m +    bool have_support_material = config->opt_bool("enable_support") || have_raft;[m
[32m +    bool is_advanced_raft = config->opt_bool("raft_advanced_params");[m
[32m +    toggle_line("raft_advanced_params", have_raft);[m
[32m +    toggle_line("raft_base_density", have_raft && is_advanced_raft);[m
[32m +    toggle_line("raft_interface_density", have_raft && is_advanced_raft);[m
[32m +[m
[32m +[m
[32m +    SupportType support_type = config->opt_enum<SupportType>("support_type");[m
[32m +    bool have_support_interface = config->opt_int("support_interface_top_layers") > 0 || config->opt_int("support_interface_bottom_layers") > 0;[m
[32m +    bool have_support_soluble = have_support_material && config->opt_float("support_top_z_distance") == 0;[m
[32m +    auto support_style = config->opt_enum<SupportMaterialStyle>("support_style");[m
[32m +    for (auto el : { "support_style", "support_base_pattern",[m
[32m +        "support_base_pattern_spacing", "support_expansion", "support_angle",[m
[32m +        "support_interface_pattern", "support_interface_top_layers", "support_interface_bottom_layers",[m
[32m +        "bridge_no_support", "max_bridge_length", "support_top_z_distance", "support_bottom_z_distance",[m
[32m +        "support_type", "support_on_build_plate_only", "support_critical_regions_only", "support_interface_not_for_body",[m
[32m +        "support_object_xy_distance", "support_object_first_layer_gap", "independent_support_layer_height"})[m
          toggle_field(el, have_support_material);[m
[31m -    toggle_field("support_material_threshold", have_support_material_auto);[m
[31m -    toggle_field("support_material_bottom_contact_distance", have_support_material && ! have_support_soluble);[m
[31m -    toggle_field("support_material_closing_radius", have_support_material && support_material_style == smsSnug);[m
[32m +    toggle_field("support_threshold_angle", have_support_material && is_auto(support_type));[m
[32m +    toggle_field("support_threshold_overlap", config->opt_int("support_threshold_angle") == 0 && have_support_material && is_auto(support_type));[m
[32m +    //toggle_field("support_closing_radius", have_support_material && support_style == smsSnug);[m
[32m +[m
[32m +    bool support_is_tree = config->opt_bool("enable_support") && is_tree(support_type);[m
[32m +    bool support_is_normal_tree = support_is_tree && support_style != smsTreeOrganic &&[m
[32m +    // Orca: use organic as default[m
[32m +    support_style != smsDefault;[m
[32m +    bool support_is_organic = support_is_tree && !support_is_normal_tree;[m
[32m +    // settings shared by normal and organic trees[m
[32m +    for (auto el : {"tree_support_branch_angle", "tree_support_branch_distance", "tree_support_branch_diameter" })[m
[32m +        toggle_line(el, support_is_normal_tree);[m
[32m +    // settings specific to normal trees[m
[32m +    for (auto el : {"tree_support_auto_brim", "tree_support_brim_width", "tree_support_adaptive_layer_height"})[m
[32m +        toggle_line(el, support_is_normal_tree);[m
[32m +    // settings specific to organic trees[m
[32m +    for (auto el : {"tree_support_branch_angle_organic", "tree_support_branch_distance_organic", "tree_support_branch_diameter_organic", "tree_support_angle_slow", "tree_support_tip_diameter", "tree_support_top_rate", "tree_support_branch_diameter_angle"})[m
[32m +        toggle_line(el, support_is_organic);[m
  [m
[31m -    for (auto el : { "support_material_bottom_interface_layers", "support_material_interface_spacing", "support_material_interface_extruder",[m
[31m -                    "support_material_interface_speed", "support_material_interface_contact_loops" })[m
[32m +    toggle_field("tree_support_brim_width", support_is_tree && !config->opt_bool("tree_support_auto_brim"));[m
[32m +    // tree support use max_bridge_length instead of bridge_no_support[m
[32m +    toggle_line("max_bridge_length", support_is_tree);[m
[32m +    toggle_line("bridge_no_support", !support_is_tree);[m
[32m +    toggle_line("support_critical_regions_only", is_auto(support_type) && support_is_tree);[m
[32m +[m
[32m +    for (auto el : { "support_interface_filament",[m
[32m +        "support_interface_loop_pattern", "support_bottom_interface_spacing" })[m
          toggle_field(el, have_support_material && have_support_interface);[m
[31m -    toggle_field("support_material_synchronize_layers", have_support_soluble);[m
  [m
[31m -    toggle_field("perimeter_extrusion_width", have_perimeters || have_skirt || have_brim);[m
[31m -    toggle_field("support_material_extruder", have_support_material || have_skirt);[m
[31m -    toggle_field("support_material_speed", have_support_material || have_brim || have_skirt);[m
[32m +    bool can_ironing_support = have_raft || (have_support_material && config->opt_int("support_interface_top_layers") > 0);[m
[32m +    toggle_field("support_ironing", can_ironing_support);[m
[32m +    bool has_support_ironing = can_ironing_support && config->opt_bool("support_ironing");[m
[32m +    for (auto el : {"support_ironing_pattern", "support_ironing_flow", "support_ironing_spacing" })[m
[32m +        toggle_line(el, has_support_ironing);[m
[32m +    // Orca: Force solid support interface when using support ironing[m
[32m +    toggle_field("support_interface_spacing", have_support_material && have_support_interface && !has_support_ironing);[m
  [m
[32m++<<<<<<< HEAD[m
[32m +//    see issue #10915[m
[32m +//    bool have_skirt_height = have_skirt &&[m
[32m +//    (config->opt_int("skirt_height") > 1 || config->opt_enum<DraftShield>("draft_shield") != dsEnabled);[m
[32m +//    toggle_line("support_speed", have_support_material || have_skirt_height);[m
[32m +//    toggle_line("support_interface_speed", have_support_material && have_support_interface);[m
[32m++=======[m
[32m+     toggle_field("raft_contact_distance", have_raft && !have_support_soluble);[m
[32m+     for (auto el : { "raft_expansion", "first_layer_acceleration_over_raft", "first_layer_speed_over_raft" })[m
[32m+         toggle_field(el, have_raft);[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
[32m +[m
[32m +    // BBS[m
[32m +    //toggle_field("support_material_synchronize_layers", have_support_soluble);[m
[32m +[m
[32m +    toggle_field("inner_wall_line_width", have_perimeters || have_skirt || have_brim);[m
[32m +    toggle_field("support_filament", have_support_material || have_skirt);[m
[32m +[m
[32m +    toggle_line("raft_contact_distance", have_raft && !have_support_soluble);[m
  [m
[31m -    bool has_ironing = config->opt_bool("ironing");[m
[31m -    for (auto el : { "ironing_type", "ironing_flowrate", "ironing_spacing", "ironing_speed" })[m
[31m -    	toggle_field(el, has_ironing);[m
[32m +    // Orca: Raft, grid, snug and organic supports use these two parameters to control the size & density of the "brim"/flange[m
[32m +    for (auto el : { "raft_first_layer_expansion", "raft_first_layer_density"})[m
[32m +        toggle_field(el, have_support_material && !(support_is_normal_tree && !have_raft));[m
  [m
[31m -    bool have_sequential_printing = config->opt_bool("complete_objects");[m
[31m -    for (auto el : { "extruder_clearance_radius", "extruder_clearance_height" })[m
[31m -        toggle_field(el, have_sequential_printing);[m
[32m +    bool has_ironing = (config->opt_enum<IroningType>("ironing_type") != IroningType::NoIroning);[m
[32m +    for (auto el : { "ironing_pattern", "ironing_flow", "ironing_spacing", "ironing_angle", "ironing_inset", "ironing_angle_fixed" })[m
[32m +        toggle_line(el, has_ironing);[m
[32m +    bool has_rectilinear_ironing = (config->opt_enum<InfillPattern>("ironing_pattern") == InfillPattern::ipRectilinear);[m
[32m +    for (auto el : {"ironing_angle", "ironing_angle_fixed"})[m
[32m +        toggle_field(el, has_ironing && has_rectilinear_ironing);[m
[32m +    [m
[32m +    toggle_line("ironing_speed", has_ironing || has_support_ironing);[m
  [m
[32m +    bool have_sequential_printing = (config->opt_enum<PrintSequence>("print_sequence") == PrintSequence::ByObject);[m
[32m +    // for (auto el : { "extruder_clearance_radius", "extruder_clearance_height_to_rod", "extruder_clearance_height_to_lid" })[m
[32m +    //     toggle_field(el, have_sequential_printing);[m
[32m +    toggle_field("print_order", !have_sequential_printing);[m
[32m +[m
[32m +    toggle_field("single_extruder_multi_material", !is_BBL_Printer);[m
[32m +[m
[32m +    auto bSEMM = preset_bundle->printers.get_edited_preset().config.opt_bool("single_extruder_multi_material");[m
[32m +    const bool supports_wipe_tower_2 = !is_BBL_Printer && preset_bundle->printers.get_edited_preset().config.opt_enum<WipeTowerType>("wipe_tower_type") == WipeTowerType::Type2;[m
[32m +[m
[32m +    toggle_field("ooze_prevention", !bSEMM);[m
      bool have_ooze_prevention = config->opt_bool("ooze_prevention");[m
[31m -    toggle_field("standby_temperature_delta", have_ooze_prevention);[m
[32m +    toggle_line("standby_temperature_delta", have_ooze_prevention);[m
[32m +    toggle_line("preheat_time", have_ooze_prevention);[m
[32m +    int preheat_steps = config->opt_int("preheat_steps");[m
[32m +    toggle_line("preheat_steps", have_ooze_prevention && (preheat_steps > 0));[m
[32m +[m
[32m +    bool have_prime_tower = config->opt_bool("enable_prime_tower");[m
[32m +    for (auto el : {"prime_tower_width", "prime_tower_brim_width", "prime_tower_skip_points", "wipe_tower_wall_type", "prime_tower_infill_gap","prime_tower_enable_framework", "enable_tower_interface_features"})[m
[32m +        toggle_line(el, have_prime_tower);[m
[32m +[m
[32m +    toggle_line("enable_tower_interface_cooldown_during_tower",[m
[32m +                have_prime_tower && config->opt_bool("enable_tower_interface_features"));[m
[32m +[m
[32m +    for (auto el : {"wall_filament", "sparse_infill_filament", "solid_infill_filament", "wipe_tower_filament"})[m
[32m +        toggle_line(el, !bSEMM);[m
[32m +[m
[32m +    bool purge_in_primetower = preset_bundle->printers.get_edited_preset().config.opt_bool("purge_in_prime_tower");[m
[32m +[m
[32m +    for (auto el : {"wipe_tower_rotation_angle", "wipe_tower_cone_angle",[m
[32m +                    "wipe_tower_extra_spacing", "wipe_tower_max_purge_speed",[m
[32m +                    "wipe_tower_bridging", "wipe_tower_extra_flow",[m
[32m +                    "wipe_tower_no_sparse_layers"})[m
[32m +            toggle_line(el, have_prime_tower && supports_wipe_tower_2);[m
[32m +[m
[32m +    WipeTowerWallType wipe_tower_wall_type = config->opt_enum<WipeTowerWallType>("wipe_tower_wall_type");[m
[32m +    bool have_rib_wall = (wipe_tower_wall_type == WipeTowerWallType::wtwRib)&&have_prime_tower;[m
[32m +    toggle_line("wipe_tower_cone_angle", have_prime_tower && supports_wipe_tower_2 && wipe_tower_wall_type == WipeTowerWallType::wtwCone);[m
[32m +    toggle_line("wipe_tower_extra_rib_length", have_rib_wall);[m
[32m +    toggle_line("wipe_tower_rib_width", have_rib_wall);[m
[32m +    toggle_line("wipe_tower_fillet_wall", have_rib_wall);[m
[32m +    toggle_field("prime_tower_width", have_prime_tower && (supports_wipe_tower_2 || have_rib_wall));[m
[32m +[m
[32m +    toggle_line("single_extruder_multi_material_priming", !bSEMM && have_prime_tower && supports_wipe_tower_2);[m
[32m +[m
[32m +    toggle_line("prime_volume",have_prime_tower && (!purge_in_primetower || !bSEMM));[m
[32m +[m
[32m +    for (auto el : {"flush_into_infill", "flush_into_support", "flush_into_objects"})[m
[32m +        toggle_field(el, have_prime_tower);[m
  [m
[31m -    bool have_wipe_tower = config->opt_bool("wipe_tower");[m
[31m -    for (auto el : { "wipe_tower_x", "wipe_tower_y", "wipe_tower_width", "wipe_tower_rotation_angle", "wipe_tower_brim_width",[m
[31m -                     "wipe_tower_bridging", "wipe_tower_no_sparse_layers", "single_extruder_multi_material_priming" })[m
[31m -        toggle_field(el, have_wipe_tower);[m
[32m +    bool have_avoid_crossing_perimeters = config->opt_bool("reduce_crossing_wall");[m
[32m +    toggle_line("max_travel_detour_distance", have_avoid_crossing_perimeters);[m
  [m
[31m -    bool have_avoid_crossing_perimeters = config->opt_bool("avoid_crossing_perimeters");[m
[31m -    toggle_field("avoid_crossing_perimeters_max_detour", have_avoid_crossing_perimeters);[m
[32m +    bool has_set_other_flow_ratios = config->opt_bool("set_other_flow_ratios");[m
[32m +    for (auto el : {"first_layer_flow_ratio", "outer_wall_flow_ratio", "inner_wall_flow_ratio", "overhang_flow_ratio", "sparse_infill_flow_ratio", "internal_solid_infill_flow_ratio", "gap_fill_flow_ratio", "support_flow_ratio", "support_interface_flow_ratio"})[m
[32m +        toggle_line(el, has_set_other_flow_ratios);[m
[32m +[m
[32m +    bool has_overhang_speed = config->opt_bool("enable_overhang_speed");[m
[32m +    for (auto el : {"overhang_1_4_speed", "overhang_2_4_speed", "overhang_3_4_speed", "overhang_4_4_speed"})[m
[32m +        toggle_line(el, has_overhang_speed);[m
[32m +[m
[32m +    toggle_line("slowdown_for_curled_perimeters", has_overhang_speed);[m
[32m +[m
[32m +    toggle_line("flush_into_objects", !is_global_config);[m
[32m +[m
[32m +    toggle_line("support_interface_not_for_body",config->opt_int("support_interface_filament")&&!config->opt_int("support_filament"));[m
[32m +[m
[32m +    // Get the current fuzzy skin state[m
[32m +    bool has_fuzzy_skin = config->opt_enum<FuzzySkinType>("fuzzy_skin") != FuzzySkinType::Disabled_fuzzy;[m
[32m +    [m
[32m +    // Show fuzzy skin options when fuzzy skin is not disabled[m
[32m +    for (auto el : {"fuzzy_skin_mode", "fuzzy_skin_noise_type", "fuzzy_skin_point_distance", "fuzzy_skin_thickness", "fuzzy_skin_first_layer"})[m
[32m +        toggle_line(el, has_fuzzy_skin);[m
[32m +    [m
[32m +    // Show noise type specific options with the same logic[m
[32m +    NoiseType fuzzy_skin_noise_type = config->opt_enum<NoiseType>("fuzzy_skin_noise_type");[m
[32m +    toggle_line("fuzzy_skin_scale", fuzzy_skin_noise_type != NoiseType::Classic && has_fuzzy_skin);[m
[32m +    toggle_line("fuzzy_skin_octaves", fuzzy_skin_noise_type != NoiseType::Classic && fuzzy_skin_noise_type != NoiseType::Voronoi && has_fuzzy_skin);[m
[32m +    toggle_line("fuzzy_skin_persistence", (fuzzy_skin_noise_type == NoiseType::Perlin || fuzzy_skin_noise_type == NoiseType::Billow) && has_fuzzy_skin);[m
[32m +[m
[32m +    bool have_arachne = config->opt_enum<PerimeterGeneratorType>("wall_generator") == PerimeterGeneratorType::Arachne;[m
[32m +    for (auto el : {"wall_transition_length", "wall_transition_filter_deviation", "wall_transition_angle",[m
[32m +        "min_feature_size", "min_length_factor", "min_bead_width", "wall_distribution_count", "initial_layer_min_bead_width"})[m
[32m +        toggle_line(el, have_arachne);[m
[32m +    toggle_field("detect_thin_wall", !have_arachne);[m
[32m +[m
[32m +    // Orca[m
[32m +    auto is_role_based_wipe_speed = config->opt_bool("role_based_wipe_speed");[m
[32m +    toggle_field("wipe_speed",!is_role_based_wipe_speed);[m
[32m +[m
[32m +    for (auto el : {"accel_to_decel_enable", "accel_to_decel_factor"})[m
[32m +        toggle_line(el, gcflavor == gcfKlipper);[m
[32m +    if(gcflavor == gcfKlipper)[m
[32m +        toggle_field("accel_to_decel_factor", config->opt_bool("accel_to_decel_enable"));[m
[32m +[m
[32m +    bool have_make_overhang_printable = config->opt_bool("make_overhang_printable");[m
[32m +    toggle_line("make_overhang_printable_angle", have_make_overhang_printable);[m
[32m +    toggle_line("make_overhang_printable_hole_size", have_make_overhang_printable);[m
[32m +[m
[32m +    toggle_line("min_width_top_surface", config->opt_bool("only_one_wall_top") || ((config->opt_float("min_length_factor") > 0.5f) && have_arachne)); // 0.5 is default value[m
[32m +[m
[32m +    for (auto el : { "hole_to_polyhole_threshold", "hole_to_polyhole_twisted" })[m
[32m +        toggle_line(el, config->opt_bool("hole_to_polyhole"));[m
[32m +[m
[32m +    bool has_detect_overhang_wall = config->opt_bool("detect_overhang_wall");[m
[32m +    bool has_overhang_reverse     = config->opt_bool("overhang_reverse");[m
[32m +    bool allow_overhang_reverse   = !has_spiral_vase;[m
[32m +    toggle_line("overhang_reverse", allow_overhang_reverse);[m
[32m +    toggle_line("overhang_reverse_internal_only", allow_overhang_reverse && has_overhang_reverse);[m
[32m +    bool has_overhang_reverse_internal_only = config->opt_bool("overhang_reverse_internal_only");[m
[32m +    if (has_overhang_reverse_internal_only){[m
[32m +        DynamicPrintConfig new_conf = *config;[m
[32m +        new_conf.set_key_value("overhang_reverse_threshold", new ConfigOptionFloatOrPercent(0,true));[m
[32m +        apply(config, &new_conf);[m
[32m +    }[m
[32m +    toggle_line("overhang_reverse_threshold", has_detect_overhang_wall && allow_overhang_reverse && has_overhang_reverse && !has_overhang_reverse_internal_only);[m
[32m +    toggle_line("timelapse_type", is_BBL_Printer);[m
[32m +[m
[32m +[m
[32m +    bool have_small_area_infill_flow_compensation = config->opt_bool("small_area_infill_flow_compensation");[m
[32m +    toggle_line("small_area_infill_flow_compensation_model", have_small_area_infill_flow_compensation);[m
[32m +[m
[32m +[m
[32m +    toggle_field("seam_slope_type", !has_spiral_vase);[m
[32m +    bool has_seam_slope = !has_spiral_vase && config->opt_enum<SeamScarfType>("seam_slope_type") != SeamScarfType::None;[m
[32m +    toggle_line("seam_slope_conditional", has_seam_slope);[m
[32m +    toggle_line("seam_slope_start_height", has_seam_slope);[m
[32m +    toggle_line("seam_slope_entire_loop", has_seam_slope);[m
[32m +    toggle_line("seam_slope_min_length", has_seam_slope);[m
[32m +    toggle_line("seam_slope_steps", has_seam_slope);[m
[32m +    toggle_line("seam_slope_inner_walls", has_seam_slope);[m
[32m +    toggle_line("scarf_joint_speed", has_seam_slope);[m
[32m +    toggle_line("scarf_joint_flow_ratio", has_seam_slope);[m
[32m +    toggle_field("seam_slope_min_length", !config->opt_bool("seam_slope_entire_loop"));[m
[32m +    toggle_line("scarf_angle_threshold", has_seam_slope && config->opt_bool("seam_slope_conditional"));[m
[32m +    toggle_line("scarf_overhang_threshold", has_seam_slope && config->opt_bool("seam_slope_conditional"));[m
[32m +[m
[32m +    bool use_beam_interlocking = config->opt_bool("interlocking_beam");[m
[32m +    toggle_line("mmu_segmented_region_interlocking_depth", !use_beam_interlocking);[m
[32m +    toggle_line("interlocking_beam_width", use_beam_interlocking);[m
[32m +    toggle_line("interlocking_orientation", use_beam_interlocking);[m
[32m +    toggle_line("interlocking_beam_layer_count", use_beam_interlocking);[m
[32m +    toggle_line("interlocking_depth", use_beam_interlocking);[m
[32m +    toggle_line("interlocking_boundary_avoidance", use_beam_interlocking);[m
[32m +[m
[32m +    bool lattice_options = config->opt_enum<InfillPattern>("sparse_infill_pattern") == InfillPattern::ipLateralLattice;[m
[32m +    for (auto el : { "lateral_lattice_angle_1", "lateral_lattice_angle_2"})[m
[32m +        toggle_line(el, lattice_options);[m
[32m +        [m
[32m +    // Adaptative Cubic and support cubic infill patterns do not support infill rotation.[m
[32m +    bool FillAdaptive = (pattern == InfillPattern::ipAdaptiveCubic || pattern == InfillPattern::ipSupportCubic);[m
[32m +[m
[32m +    //Orca: disable infill_direction/solid_infill_direction if sparse_infill_rotate_template/solid_infill_rotate_template is not empty value and adaptive cubic/support cubic infill pattern is not selected[m
[32m +    toggle_field("sparse_infill_rotate_template", !FillAdaptive);[m
[32m +    toggle_field("infill_direction", config->opt_string("sparse_infill_rotate_template") == "" && !FillAdaptive);[m
[32m +    toggle_field("solid_infill_direction", config->opt_string("solid_infill_rotate_template") == "");[m
[32m +    [m
[32m +    toggle_line("infill_overhang_angle", config->opt_enum<InfillPattern>("sparse_infill_pattern") == InfillPattern::ipLateralHoneycomb);[m
[32m +[m
[32m +    std::string printer_type = wxGetApp().preset_bundle->printers.get_edited_preset().get_printer_type(wxGetApp().preset_bundle);[m
[32m +    toggle_line("enable_wrapping_detection", DevPrinterConfigUtil::support_wrapping_detection(printer_type));[m
  }[m
  [m
  void ConfigManipulation::update_print_sla_config(DynamicPrintConfig* config, const bool is_global_config/* = false*/)[m
[1mdiff --cc src/slic3r/GUI/Tab.cpp[m
[1mindex b8b883f0be,86089f729e..0000000000[m
[1m--- a/src/slic3r/GUI/Tab.cpp[m
[1m+++ b/src/slic3r/GUI/Tab.cpp[m
[36m@@@ -2274,443 -1408,258 +2274,616 @@@[m [mvoid Tab::update_frequently_changed_par[m
      }[m
  }[m
  [m
[32m +//BBS: BBS new parameter list[m
  void TabPrint::build()[m
  {[m
[31m -    m_presets = &m_preset_bundle->prints;[m
[32m +    if (m_presets == nullptr)[m
[32m +        m_presets = &m_preset_bundle->prints;[m
      load_initial_data();[m
  [m
[31m -    auto page = add_options_page(L("Layers and perimeters"), "layers");[m
[31m -        wxString category_path = "layers-and-perimeters_1748#";[m
[31m -        auto optgroup = page->new_optgroup(L("Layer height"));[m
[31m -        optgroup->append_single_option_line("layer_height", category_path + "layer-height");[m
[31m -        optgroup->append_single_option_line("first_layer_height", category_path + "first-layer-height");[m
[31m -[m
[31m -        optgroup = page->new_optgroup(L("Vertical shells"));[m
[31m -        optgroup->append_single_option_line("perimeters", category_path + "perimeters");[m
[31m -        optgroup->append_single_option_line("spiral_vase", category_path + "spiral-vase");[m
[31m -[m
[31m -        Line line { "", "" };[m
[31m -        line.full_width = 1;[m
[31m -        line.label_path = category_path + "recommended-thin-wall-thickness";[m
[31m -        line.widget = [this](wxWindow* parent) {[m
[31m -            return description_line_widget(parent, &m_recommended_thin_wall_thickness_description_line);[m
[31m -        };[m
[31m -        optgroup->append_line(line);[m
[31m -[m
[31m -        optgroup = page->new_optgroup(L("Horizontal shells"));[m
[31m -        line = { L("Solid layers"), "" };[m
[31m -        line.label_path = category_path + "solid-layers-top-bottom";[m
[31m -        line.append_option(optgroup->get_option("top_solid_layers"));[m
[31m -        line.append_option(optgroup->get_option("bottom_solid_layers"));[m
[31m -        optgroup->append_line(line);[m
[31m -    	line = { L("Minimum shell thickness"), "" };[m
[31m -        line.append_option(optgroup->get_option("top_solid_min_thickness"));[m
[31m -        line.append_option(optgroup->get_option("bottom_solid_min_thickness"));[m
[31m -        optgroup->append_line(line);[m
[31m -		line = { "", "" };[m
[31m -	    line.full_width = 1;[m
[31m -	    line.widget = [this](wxWindow* parent) {[m
[31m -	        return description_line_widget(parent, &m_top_bottom_shell_thickness_explanation);[m
[31m -	    };[m
[31m -	    optgroup->append_line(line);[m
[31m -[m
[31m -        optgroup = page->new_optgroup(L("Quality (slower slicing)"));[m
[31m -        optgroup->append_single_option_line("extra_perimeters", category_path + "extra-perimeters-if-needed");[m
[31m -        optgroup->append_single_option_line("ensure_vertical_shell_thickness", category_path + "ensure-vertical-shell-thickness");[m
[31m -        optgroup->append_single_option_line("avoid_crossing_perimeters", category_path + "avoid-crossing-perimeters");[m
[31m -        optgroup->append_single_option_line("avoid_crossing_perimeters_max_detour", category_path + "avoid_crossing_perimeters_max_detour");[m
[31m -        optgroup->append_single_option_line("thin_walls", category_path + "detect-thin-walls");[m
[31m -        optgroup->append_single_option_line("thick_bridges", category_path + "thick_bridges");[m
[31m -        optgroup->append_single_option_line("overhangs", category_path + "detect-bridging-perimeters");[m
[31m -[m
[31m -        optgroup = page->new_optgroup(L("Advanced"));[m
[31m -        optgroup->append_single_option_line("seam_position", category_path + "seam-position");[m
[31m -        optgroup->append_single_option_line("external_perimeters_first", category_path + "external-perimeters-first");[m
[31m -        optgroup->append_single_option_line("gap_fill_enabled");[m
[31m -[m
[31m -        optgroup = page->new_optgroup(L("Fuzzy skin (experimental)"));[m
[31m -        Option option = optgroup->get_option("fuzzy_skin");[m
[31m -//        option.opt.width = 30;[m
[31m -        optgroup->append_single_option_line(option);[m
[31m -        optgroup->append_single_option_line(optgroup->get_option("fuzzy_skin_thickness"));[m
[31m -        optgroup->append_single_option_line(optgroup->get_option("fuzzy_skin_point_dist"));[m
[31m -[m
[31m -    page = add_options_page(L("Infill"), "infill");[m
[31m -        category_path = "infill_42#";[m
[31m -        optgroup = page->new_optgroup(L("Infill"));[m
[31m -        optgroup->append_single_option_line("fill_density", category_path + "fill-density");[m
[31m -        optgroup->append_single_option_line("fill_pattern", category_path + "fill-pattern");[m
[31m -        optgroup->append_single_option_line("infill_anchor", category_path + "fill-pattern");[m
[31m -        optgroup->append_single_option_line("infill_anchor_max", category_path + "fill-pattern");[m
[31m -        optgroup->append_single_option_line("top_fill_pattern", category_path + "top-fill-pattern");[m
[31m -        optgroup->append_single_option_line("bottom_fill_pattern", category_path + "bottom-fill-pattern");[m
[31m -[m
[32m +    auto page = add_options_page(L("Quality"), "custom-gcode_quality"); // ORCA: icon only visible on placeholders[m
[32m +        auto optgroup = page->new_optgroup(L("Layer height"), L"param_layer_height");[m
[32m +        optgroup->append_single_option_line("layer_height","quality_settings_layer_height");[m
[32m +        optgroup->append_single_option_line("initial_layer_print_height","quality_settings_layer_height");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Line width"), L"param_line_width");[m
[32m +        optgroup->append_single_option_line("line_width","quality_settings_line_width");[m
[32m +        optgroup->append_single_option_line("initial_layer_line_width","quality_settings_line_width");[m
[32m +        optgroup->append_single_option_line("outer_wall_line_width","quality_settings_line_width");[m
[32m +        optgroup->append_single_option_line("inner_wall_line_width","quality_settings_line_width");[m
[32m +        optgroup->append_single_option_line("top_surface_line_width","quality_settings_line_width");[m
[32m +        optgroup->append_single_option_line("sparse_infill_line_width","quality_settings_line_width");[m
[32m +        optgroup->append_single_option_line("internal_solid_infill_line_width","quality_settings_line_width");[m
[32m +        optgroup->append_single_option_line("support_line_width","quality_settings_line_width");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Seam"), L"param_seam");[m
[32m +        optgroup->append_single_option_line("seam_position", "quality_settings_seam#seam-position");[m
[32m +        optgroup->append_single_option_line("staggered_inner_seams", "quality_settings_seam#staggered-inner-seams");[m
[32m +        optgroup->append_single_option_line("seam_gap","quality_settings_seam#seam-gap");[m
[32m +        optgroup->append_single_option_line("seam_slope_type", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("seam_slope_conditional", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("scarf_angle_threshold", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("scarf_overhang_threshold", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("scarf_joint_speed", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("seam_slope_start_height", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("seam_slope_entire_loop", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("seam_slope_min_length", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("seam_slope_steps", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("scarf_joint_flow_ratio", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("seam_slope_inner_walls", "quality_settings_seam#scarf-joint-seam");[m
[32m +        optgroup->append_single_option_line("role_based_wipe_speed","quality_settings_seam#role-based-wipe-speed");[m
[32m +        optgroup->append_single_option_line("wipe_speed", "quality_settings_seam#wipe-speed");[m
[32m +        optgroup->append_single_option_line("wipe_on_loops","quality_settings_seam#wipe-on-loop-inward-movement");[m
[32m +        optgroup->append_single_option_line("wipe_before_external_loop","quality_settings_seam#wipe-before-external");[m
[32m +[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Precision"), L"param_precision");[m
[32m +        optgroup->append_single_option_line("slice_closing_radius", "quality_settings_precision#slice-gap-closing-radius");[m
[32m +        optgroup->append_single_option_line("resolution", "quality_settings_precision#resolution");[m
[32m +        optgroup->append_single_option_line("enable_arc_fitting", "quality_settings_precision#arc-fitting");[m
[32m +        optgroup->append_single_option_line("xy_hole_compensation", "quality_settings_precision#x-y-compensation");[m
[32m +        optgroup->append_single_option_line("xy_contour_compensation", "quality_settings_precision#x-y-compensation");[m
[32m +        optgroup->append_single_option_line("elefant_foot_compensation", "quality_settings_precision#elephant-foot-compensation");[m
[32m +        optgroup->append_single_option_line("elefant_foot_compensation_layers", "quality_settings_precision#elephant-foot-compensation");[m
[32m +        optgroup->append_single_option_line("precise_outer_wall", "quality_settings_precision#precise-wall");[m
[32m +        optgroup->append_single_option_line("precise_z_height", "quality_settings_precision#precise-z-height");[m
[32m +        optgroup->append_single_option_line("hole_to_polyhole", "quality_settings_precision#polyholes");[m
[32m +        optgroup->append_single_option_line("hole_to_polyhole_threshold", "quality_settings_precision#polyholes");[m
[32m +        optgroup->append_single_option_line("hole_to_polyhole_twisted", "quality_settings_precision#polyholes");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Ironing"), L"param_ironing");[m
[32m +        optgroup->append_single_option_line("ironing_type", "quality_settings_ironing#type");[m
[32m +        optgroup->append_single_option_line("ironing_pattern", "quality_settings_ironing#pattern");[m
[32m +        optgroup->append_single_option_line("ironing_flow", "quality_settings_ironing#flow");[m
[32m +        optgroup->append_single_option_line("ironing_spacing", "quality_settings_ironing#line-spacing");[m
[32m +        optgroup->append_single_option_line("ironing_inset", "quality_settings_ironing#inset");[m
[32m +        optgroup->append_single_option_line("ironing_angle", "quality_settings_ironing#angle-offset");[m
[32m +        optgroup->append_single_option_line("ironing_angle_fixed", "quality_settings_ironing#fixed-angle");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Wall generator"), L"param_wall_generator");[m
[32m +        optgroup->append_single_option_line("wall_generator", "quality_settings_wall_generator");[m
[32m +        optgroup->append_single_option_line("wall_transition_angle", "quality_settings_wall_generator#arachne");[m
[32m +        optgroup->append_single_option_line("wall_transition_filter_deviation", "quality_settings_wall_generator#arachne");[m
[32m +        optgroup->append_single_option_line("wall_transition_length", "quality_settings_wall_generator#arachne");[m
[32m +        optgroup->append_single_option_line("wall_distribution_count", "quality_settings_wall_generator#arachne");[m
[32m +        optgroup->append_single_option_line("initial_layer_min_bead_width", "quality_settings_wall_generator#arachne");[m
[32m +        optgroup->append_single_option_line("min_bead_width", "quality_settings_wall_generator#arachne");[m
[32m +        optgroup->append_single_option_line("min_feature_size", "quality_settings_wall_generator#arachne");[m
[32m +        optgroup->append_single_option_line("min_length_factor", "quality_settings_wall_generator#arachne");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Walls and surfaces"), L"param_wall_surface");[m
[32m +        optgroup->append_single_option_line("wall_sequence", "quality_settings_wall_and_surfaces#walls-printing-order");[m
[32m +        optgroup->append_single_option_line("is_infill_first", "quality_settings_wall_and_surfaces#print-infill-first");[m
[32m +        optgroup->append_single_option_line("wall_direction", "quality_settings_wall_and_surfaces#wall-loop-direction");[m
[32m +        optgroup->append_single_option_line("print_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("top_solid_infill_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("bottom_solid_infill_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("set_other_flow_ratios", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("first_layer_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("outer_wall_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("inner_wall_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("overhang_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("sparse_infill_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("internal_solid_infill_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("gap_fill_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("support_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("support_interface_flow_ratio", "quality_settings_wall_and_surfaces#surface-flow-ratio");[m
[32m +        optgroup->append_single_option_line("only_one_wall_first_layer", "quality_settings_wall_and_surfaces#only-one-wall");[m
[32m +        optgroup->append_single_option_line("only_one_wall_top", "quality_settings_wall_and_surfaces#only-one-wall");[m
[32m +        optgroup->append_single_option_line("min_width_top_surface", "quality_settings_wall_and_surfaces#threshold");[m
[32m +        optgroup->append_single_option_line("reduce_crossing_wall", "quality_settings_wall_and_surfaces#avoid-crossing-walls");[m
[32m +        optgroup->append_single_option_line("max_travel_detour_distance", "quality_settings_wall_and_surfaces#max-detour-length");[m
[32m +[m
[32m++<<<<<<< HEAD[m
[32m +        optgroup->append_single_option_line("small_area_infill_flow_compensation", "quality_settings_wall_and_surfaces#small-area-flow-compensation");[m
[32m +        Option option = optgroup->get_option("small_area_infill_flow_compensation_model");[m
[32m++=======[m
[32m+         optgroup = page->new_optgroup(L("Ironing"));[m
[32m+         optgroup->append_single_option_line("ironing");[m
[32m+         optgroup->append_single_option_line("ironing_type");[m
[32m+         optgroup->append_single_option_line("ironing_flowrate");[m
[32m+         optgroup->append_single_option_line("ironing_spacing");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Reducing printing time"));[m
[32m+         optgroup->append_single_option_line("infill_every_layers", category_path + "combine-infill-every-x-layers");[m
[32m+         optgroup->append_single_option_line("infill_only_where_needed", category_path + "only-infill-where-needed");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Advanced"));[m
[32m+         optgroup->append_single_option_line("solid_infill_every_layers", category_path + "solid-infill-every-x-layers");[m
[32m+         optgroup->append_single_option_line("fill_angle", category_path + "fill-angle");[m
[32m+         optgroup->append_single_option_line("solid_infill_below_area", category_path + "solid-infill-threshold-area");[m
[32m+         optgroup->append_single_option_line("bridge_angle");[m
[32m+         optgroup->append_single_option_line("only_retract_when_crossing_perimeters");[m
[32m+         optgroup->append_single_option_line("infill_first");[m
[32m+ [m
[32m+     page = add_options_page(L("Skirt and brim"), "skirt+brim");[m
[32m+         category_path = "skirt-and-brim_133969#";[m
[32m+         optgroup = page->new_optgroup(L("Skirt"));[m
[32m+         optgroup->append_single_option_line("skirts", category_path + "skirt");[m
[32m+         optgroup->append_single_option_line("skirt_distance", category_path + "skirt");[m
[32m+         optgroup->append_single_option_line("skirt_height", category_path + "skirt");[m
[32m+         optgroup->append_single_option_line("draft_shield", category_path + "skirt");[m
[32m+         optgroup->append_single_option_line("min_skirt_length", category_path + "skirt");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Brim"));[m
[32m+         optgroup->append_single_option_line("brim_type", category_path + "brim");[m
[32m+         optgroup->append_single_option_line("brim_width", category_path + "brim");[m
[32m+         optgroup->append_single_option_line("brim_separation", category_path + "brim");[m
[32m+ [m
[32m+     page = add_options_page(L("Support material"), "support");[m
[32m+         category_path = "support-material_1698#";[m
[32m+         optgroup = page->new_optgroup(L("Support material"));[m
[32m+         optgroup->append_single_option_line("support_material", category_path + "generate-support-material");[m
[32m+         optgroup->append_single_option_line("support_material_auto", category_path + "auto-generated-supports");[m
[32m+         optgroup->append_single_option_line("support_material_threshold", category_path + "overhang-threshold");[m
[32m+         optgroup->append_single_option_line("support_material_enforce_layers", category_path + "enforce-support-for-the-first");[m
[32m+         optgroup->append_single_option_line("raft_first_layer_density", category_path + "raft-first-layer-density");[m
[32m+         optgroup->append_single_option_line("raft_first_layer_expansion", category_path + "raft-first-layer-expansion");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Raft"));[m
[32m+         optgroup->append_single_option_line("raft_layers", category_path + "raft-layers");[m
[32m+         optgroup->append_single_option_line("raft_contact_distance");[m
[32m+         optgroup->append_single_option_line("raft_expansion");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Options for support material and raft"));[m
[32m+         optgroup->append_single_option_line("support_material_style", category_path + "style");[m
[32m+         optgroup->append_single_option_line("support_material_contact_distance", category_path + "contact-z-distance");[m
[32m+         optgroup->append_single_option_line("support_material_bottom_contact_distance", category_path + "contact-z-distance");[m
[32m+         optgroup->append_single_option_line("support_material_pattern", category_path + "pattern");[m
[32m+         optgroup->append_single_option_line("support_material_with_sheath", category_path + "with-sheath-around-the-support");[m
[32m+         optgroup->append_single_option_line("support_material_spacing", category_path + "pattern-spacing-0-inf");[m
[32m+         optgroup->append_single_option_line("support_material_angle", category_path + "pattern-angle");[m
[32m+         optgroup->append_single_option_line("support_material_closing_radius", category_path + "pattern-angle");[m
[32m+         optgroup->append_single_option_line("support_material_interface_layers", category_path + "interface-layers");[m
[32m+         optgroup->append_single_option_line("support_material_bottom_interface_layers", category_path + "interface-layers");[m
[32m+         optgroup->append_single_option_line("support_material_interface_pattern", category_path + "interface-pattern");[m
[32m+         optgroup->append_single_option_line("support_material_interface_spacing", category_path + "interface-pattern-spacing");[m
[32m+         optgroup->append_single_option_line("support_material_interface_contact_loops", category_path + "interface-loops");[m
[32m+         optgroup->append_single_option_line("support_material_buildplate_only", category_path + "support-on-build-plate-only");[m
[32m+         optgroup->append_single_option_line("support_material_xy_spacing", category_path + "xy-separation-between-an-object-and-its-support");[m
[32m+         optgroup->append_single_option_line("dont_support_bridges", category_path + "dont-support-bridges");[m
[32m+         optgroup->append_single_option_line("support_material_synchronize_layers", category_path + "synchronize-with-object-layers");[m
[32m+ [m
[32m+     page = add_options_page(L("Speed"), "time");[m
[32m+         optgroup = page->new_optgroup(L("Speed for print moves"));[m
[32m+         optgroup->append_single_option_line("perimeter_speed");[m
[32m+         optgroup->append_single_option_line("small_perimeter_speed");[m
[32m+         optgroup->append_single_option_line("external_perimeter_speed");[m
[32m+         optgroup->append_single_option_line("infill_speed");[m
[32m+         optgroup->append_single_option_line("solid_infill_speed");[m
[32m+         optgroup->append_single_option_line("top_solid_infill_speed");[m
[32m+         optgroup->append_single_option_line("support_material_speed");[m
[32m+         optgroup->append_single_option_line("support_material_interface_speed");[m
[32m+         optgroup->append_single_option_line("bridge_speed");[m
[32m+         optgroup->append_single_option_line("gap_fill_speed");[m
[32m+         optgroup->append_single_option_line("ironing_speed");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Speed for non-print moves"));[m
[32m+         optgroup->append_single_option_line("travel_speed");[m
[32m+         optgroup->append_single_option_line("travel_speed_z");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Modifiers"));[m
[32m+         optgroup->append_single_option_line("first_layer_speed");[m
[32m+         optgroup->append_single_option_line("first_layer_speed_over_raft");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Acceleration control (advanced)"));[m
[32m+         optgroup->append_single_option_line("perimeter_acceleration");[m
[32m+         optgroup->append_single_option_line("infill_acceleration");[m
[32m+         optgroup->append_single_option_line("bridge_acceleration");[m
[32m+         optgroup->append_single_option_line("first_layer_acceleration");[m
[32m+         optgroup->append_single_option_line("first_layer_acceleration_over_raft");[m
[32m+         optgroup->append_single_option_line("default_acceleration");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Autospeed (advanced)"));[m
[32m+         optgroup->append_single_option_line("max_print_speed", "max-volumetric-speed_127176");[m
[32m+         optgroup->append_single_option_line("max_volumetric_speed", "max-volumetric-speed_127176");[m
[32m+ #ifdef HAS_PRESSURE_EQUALIZER[m
[32m+         optgroup->append_single_option_line("max_volumetric_extrusion_rate_slope_positive");[m
[32m+         optgroup->append_single_option_line("max_volumetric_extrusion_rate_slope_negative");[m
[32m+ #endif /* HAS_PRESSURE_EQUALIZER */[m
[32m+ [m
[32m+     page = add_options_page(L("Multiple Extruders"), "funnel");[m
[32m+         optgroup = page->new_optgroup(L("Extruders"));[m
[32m+         optgroup->append_single_option_line("perimeter_extruder");[m
[32m+         optgroup->append_single_option_line("infill_extruder");[m
[32m+         optgroup->append_single_option_line("solid_infill_extruder");[m
[32m+         optgroup->append_single_option_line("support_material_extruder");[m
[32m+         optgroup->append_single_option_line("support_material_interface_extruder");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Ooze prevention"));[m
[32m+         optgroup->append_single_option_line("ooze_prevention");[m
[32m+         optgroup->append_single_option_line("standby_temperature_delta");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Wipe tower"));[m
[32m+         optgroup->append_single_option_line("wipe_tower");[m
[32m+         optgroup->append_single_option_line("wipe_tower_x");[m
[32m+         optgroup->append_single_option_line("wipe_tower_y");[m
[32m+         optgroup->append_single_option_line("wipe_tower_width");[m
[32m+         optgroup->append_single_option_line("wipe_tower_rotation_angle");[m
[32m+         optgroup->append_single_option_line("wipe_tower_brim_width");[m
[32m+         optgroup->append_single_option_line("wipe_tower_bridging");[m
[32m+         optgroup->append_single_option_line("wipe_tower_no_sparse_layers");[m
[32m+         optgroup->append_single_option_line("single_extruder_multi_material_priming");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Advanced"));[m
[32m+         optgroup->append_single_option_line("interface_shells");[m
[32m+         optgroup->append_single_option_line("mmu_segmented_region_max_width");[m
[32m+ [m
[32m+     page = add_options_page(L("Advanced"), "wrench");[m
[32m+         optgroup = page->new_optgroup(L("Extrusion width"));[m
[32m+         optgroup->append_single_option_line("extrusion_width");[m
[32m+         optgroup->append_single_option_line("first_layer_extrusion_width");[m
[32m+         optgroup->append_single_option_line("perimeter_extrusion_width");[m
[32m+         optgroup->append_single_option_line("external_perimeter_extrusion_width");[m
[32m+         optgroup->append_single_option_line("infill_extrusion_width");[m
[32m+         optgroup->append_single_option_line("solid_infill_extrusion_width");[m
[32m+         optgroup->append_single_option_line("top_infill_extrusion_width");[m
[32m+         optgroup->append_single_option_line("support_material_extrusion_width");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Overlap"));[m
[32m+         optgroup->append_single_option_line("infill_overlap");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Flow"));[m
[32m+         optgroup->append_single_option_line("bridge_flow_ratio");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Slicing"));[m
[32m+         optgroup->append_single_option_line("slice_closing_radius");[m
[32m+         optgroup->append_single_option_line("slicing_mode");[m
[32m+         optgroup->append_single_option_line("resolution");[m
[32m+         optgroup->append_single_option_line("xy_size_compensation");[m
[32m+         optgroup->append_single_option_line("elefant_foot_compensation", "elephant-foot-compensation_114487");[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Other"));[m
[32m+         optgroup->append_single_option_line("clip_multipart_objects");[m
[32m+ [m
[32m+     page = add_options_page(L("Output options"), "output+page_white");[m
[32m+         optgroup = page->new_optgroup(L("Sequential printing"));[m
[32m+         optgroup->append_single_option_line("complete_objects", "sequential-printing_124589");[m
[32m+         line = { L("Extruder clearance"), "" };[m
[32m+         line.append_option(optgroup->get_option("extruder_clearance_radius"));[m
[32m+         line.append_option(optgroup->get_option("extruder_clearance_height"));[m
[32m+         optgroup->append_line(line);[m
[32m+ [m
[32m+         optgroup = page->new_optgroup(L("Output file"));[m
[32m+         optgroup->append_single_option_line("gcode_comments");[m
[32m+         optgroup->append_single_option_line("gcode_label_objects");[m
[32m+         option = optgroup->get_option("output_filename_format");[m
[32m++>>>>>>> b29c0ead7d (Implemented configurable speed and acceleration settings for the first)[m
          option.opt.full_width = true;[m
[31m -        optgroup->append_single_option_line(option);[m
[32m +        option.opt.is_code = true;[m
[32m +        option.opt.height = 15;[m
[32m +        optgroup->append_single_option_line(option, "quality_settings_wall_and_surfaces#small-area-flow-compensation");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Bridging"), L"param_bridge");[m
[32m +        optgroup->append_single_option_line("bridge_flow", "quality_settings_bridging#flow-ratio");[m
[32m +	    optgroup->append_single_option_line("internal_bridge_flow", "quality_settings_bridging#flow-ratio");[m
[32m +        optgroup->append_single_option_line("bridge_density", "quality_settings_bridging#bridge-density");[m
[32m +        optgroup->append_single_option_line("internal_bridge_density", "quality_settings_bridging#bridge-density");[m
[32m +        optgroup->append_single_option_line("thick_bridges", "quality_settings_bridging#thick-bridges");[m
[32m +        optgroup->append_single_option_line("thick_internal_bridges", "quality_settings_bridging#thick-bridges");[m
[32m +        optgroup->append_single_option_line("enable_extra_bridge_layer", "quality_settings_bridging#extra-bridge-layers");[m
[32m +        optgroup->append_single_option_line("dont_filter_internal_bridges", "quality_settings_bridging#filter-out-small-internal-bridges");[m
[32m +        optgroup->append_single_option_line("counterbore_hole_bridging", "quality_settings_bridging#bridge-counterbore-hole");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Overhangs"), L"param_overhang");[m
[32m +        optgroup->append_single_option_line("detect_overhang_wall", "quality_settings_overhangs#detect-overhang-wall");[m
[32m +        optgroup->append_single_option_line("make_overhang_printable", "quality_settings_overhangs#make-overhang-printable");[m
[32m +        optgroup->append_single_option_line("make_overhang_printable_angle", "quality_settings_overhangs#maximum-angle");[m
[32m +        optgroup->append_single_option_line("make_overhang_printable_hole_size", "quality_settings_overhangs#hole-area");[m
[32m +        optgroup->append_single_option_line("extra_perimeters_on_overhangs", "quality_settings_overhangs#extra-perimeters-on-overhangs");[m
[32m +        optgroup->append_single_option_line("overhang_reverse", "quality_settings_overhangs#reverse-on-even");[m
[32m +        optgroup->append_single_option_line("overhang_reverse_internal_only", "quality_settings_overhangs#reverse-internal-only");[m
[32m +        optgroup->append_single_option_line("overhang_reverse_threshold", "quality_settings_overhangs#reverse-threshold");[m
[32m +[m
[32m +    page = add_options_page(L("Strength"), "custom-gcode_strength"); // ORCA: icon only visible on placeholders[m
[32m +        optgroup = page->new_optgroup(L("Walls"), L"param_wall");[m
[32m +        optgroup->append_single_option_line("wall_loops", "strength_settings_walls#wall-loops");[m
[32m +        optgroup->append_single_option_line("alternate_extra_wall", "strength_settings_walls#alternate-extra-wall");[m
[32m +        optgroup->append_single_option_line("detect_thin_wall", "strength_settings_walls#detect-thin-wall");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Top/bottom shells"), L"param_shell");[m
[32m +[m
[32m +        optgroup->append_single_option_line("top_shell_layers", "strength_settings_top_bottom_shells#shell-layers");[m
[32m +        optgroup->append_single_option_line("top_shell_thickness", "strength_settings_top_bottom_shells#shell-thickness");[m
[32m +        optgroup->append_single_option_line("top_surface_density", "strength_settings_top_bottom_shells#surface-density");[m
[32m +        optgroup->append_single_option_line("top_surface_pattern", "strength_settings_top_bottom_shells#surface-pattern");[m
[32m +        optgroup->append_single_option_line("bottom_shell_layers", "strength_settings_top_bottom_shells#shell-layers");[m
[32m +        optgroup->append_single_option_line("bottom_shell_thickness", "strength_settings_top_bottom_shells#shell-thickness");[m
[32m +        optgroup->append_single_option_line("bottom_surface_density", "strength_settings_top_bottom_shells#surface-density");[m
[32m +        optgroup->append_single_option_line("bottom_surface_pattern", "strength_settings_top_bottom_shells#surface-pattern");[m
[32m +        optgroup->append_single_option_line("top_bottom_infill_wall_overlap", "strength_settings_top_bottom_shells#infillwall-overlap");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Infill"), L"param_infill");[m
[32m +        optgroup->append_single_option_line("sparse_infill_density", "strength_settings_infill#sparse-infill-density");[m
[32m +        optgroup->append_single_option_line("fill_multiline", "strength_settings_infill#fill-multiline");[m
[32m +        optgroup->append_single_option_line("sparse_infill_pattern", "strength_settings_infill#sparse-infill-pattern");[m
[32m +        optgroup->append_single_option_line("infill_direction", "strength_settings_infill#direction");[m
[32m +        optgroup->append_single_option_line("sparse_infill_rotate_template", "strength_settings_infill_rotation_template_metalanguage");[m
[32m +        optgroup->append_single_option_line("skin_infill_density", "strength_settings_patterns#locked-zag");[m
[32m +        optgroup->append_single_option_line("skeleton_infill_density", "strength_settings_patterns#locked-zag");[m
[32m +        optgroup->append_single_option_line("infill_lock_depth", "strength_settings_patterns#locked-zag");[m
[32m +        optgroup->append_single_option_line("skin_infill_depth", "strength_settings_patterns#locked-zag");[m
[32m +        optgroup->append_single_option_line("skin_infill_line_width", "strength_settings_patterns#locked-zag");[m
[32m +        optgroup->append_single_option_line("skeleton_infill_line_width", "strength_settings_patterns#locked-zag");[m
[32m +        optgroup->append_single_option_line("symmetric_infill_y_axis", "strength_settings_infill#symmetric-infill-y-axis");[m
[32m +        optgroup->append_single_option_line("infill_shift_step", "strength_settings_patterns#cross-hatch");[m
[32m +        optgroup->append_single_option_line("lateral_lattice_angle_1", "strength_settings_patterns#lateral-lattice");[m
[32m +        optgroup->append_single_option_line("lateral_lattice_angle_2", "strength_settings_patterns#lateral-lattice");[m
[32m +        optgroup->append_single_option_line("infill_overhang_angle", "strength_settings_patterns#lateral-honeycomb");[m
[32m +        optgroup->append_single_option_line("infill_anchor_max", "strength_settings_infill#anchor");[m
[32m +        optgroup->append_single_option_line("infill_anchor", "strength_settings_infill#anchor");[m
[32m +        optgroup->append_single_option_line("internal_solid_infill_pattern", "strength_settings_infill#internal-solid-infill");[m
[32m +        optgroup->append_single_option_line("solid_infill_direction", "strength_settings_infill#direction");[m
[32m +        optgroup->append_single_option_line("solid_infill_rotate_template", "strength_settings_infill_rotation_template_metalanguage");[m
[32m +        optgroup->append_single_option_line("gap_fill_target", "strength_settings_infill#apply-gap-fill");[m
[32m +        optgroup->append_single_option_line("filter_out_gap_fill", "strength_settings_infill#filter-out-tiny-gaps");[m
[32m +        optgroup->append_single_option_line("infill_wall_overlap", "strength_settings_infill#infill-wall-overlap");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Advanced"), L"param_advanced");[m
[32m +        optgroup->append_single_option_line("align_infill_direction_to_model", "strength_settings_advanced#align-infill-direction-to-model");[m
[32m +        optgroup->append_single_option_line("extra_solid_infills", "strength_settings_infill#extra-solid-infill");[m
[32m +        optgroup->append_single_option_line("bridge_angle", "strength_settings_advanced#bridge-infill-direction");[m
[32m +        optgroup->append_single_option_line("internal_bridge_angle", "strength_settings_advanced#bridge-infill-direction"); // ORCA: Internal bridge angle override[m
[32m +        optgroup->append_single_option_line("minimum_sparse_infill_area", "strength_settings_advanced#minimum-sparse-infill-threshold");[m
[32m +        optgroup->append_single_option_line("infill_combination", "strength_settings_advanced#infill-combination");[m
[32m +        optgroup->append_single_option_line("infill_combination_max_layer_height", "strength_settings_advanced#max-layer-height");[m
[32m +        optgroup->append_single_option_line("detect_narrow_internal_solid_infill", "strength_settings_advanced#detect-narrow-internal-solid-infill");[m
[32m +        optgroup->append_single_option_line("ensure_vertical_shell_thickness", "strength_settings_advanced#ensure-vertical-shell-thickness");[m
[32m +[m
[32m +    page = add_options_page(L("Speed"), "custom-gcode_speed"); // ORCA: icon only visible on placeholders[m
[32m +        optgroup = page->new_optgroup(L("First layer speed"), L"param_speed_first", 15);[m
[32m +        optgroup->append_single_option_line("initial_layer_speed", "speed_settings_initial_layer_speed#initial-layer");[m
[32m +        optgroup->append_single_option_line("initial_layer_infill_speed", "speed_settings_initial_layer_speed#initial-layer-infill");[m
[32m +        optgroup->append_single_option_line("initial_layer_travel_speed", "speed_settings_initial_layer_speed#initial-layer-travel-speed");[m
[32m +        optgroup->append_single_option_line("slow_down_layers", "speed_settings_initial_layer_speed#number-of-slow-layers");[m
[32m +        optgroup = page->new_optgroup(L("Other layers speed"), L"param_speed", 15);[m
[32m +        optgroup->append_single_option_line("outer_wall_speed", "speed_settings_other_layers_speed#outer-wall");[m
[32m +        optgroup->append_single_option_line("inner_wall_speed", "speed_settings_other_layers_speed#inner-wall");[m
[32m +        optgroup->append_single_option_line("small_perimeter_speed", "speed_settings_other_layers_speed#small-perimeters");[m
[32m +        optgroup->append_single_option_line("small_perimeter_threshold", "speed_settings_other_layers_speed#small-perimeters-threshold");[m
[32m +        optgroup->append_single_option_line("sparse_infill_speed", "speed_settings_other_layers_speed#sparse-infill");[m
[32m +        optgroup->append_single_option_line("internal_solid_infill_speed", "speed_settings_other_layers_speed#internal-solid-infill");[m
[32m +        optgroup->append_single_option_line("top_surface_speed", "speed_settings_other_layers_speed#top-surface");[m
[32m +        optgroup->append_single_option_line("gap_infill_speed", "speed_settings_other_layers_speed#gap-infill");[m
[32m +        optgroup->append_single_option_line("ironing_speed", "speed_settings_other_layers_speed#ironing-speed");[m
[32m +        optgroup->append_single_option_line("support_speed", "speed_settings_other_layers_speed#support");[m
[32m +        optgroup->append_single_option_line("support_interface_speed", "speed_settings_other_layers_speed#support-interface");[m
[32m +        optgroup = page->new_optgroup(L("Overhang speed"), L"param_overhang_speed", 15);[m
[32m +        optgroup->append_single_option_line("enable_overhang_speed", "speed_settings_overhang_speed#slow-down-for-overhang");[m
[32m +[m
[32m +        optgroup->append_single_option_line("slowdown_for_curled_perimeters", "speed_settings_overhang_speed#slow-down-for-curled-perimeters");[m
[32m +        Line line = { L("Overhang speed"), L("This is the speed for various overhang degrees. Overhang degrees are expressed as a percentage of line width. 0 speed means no slowing down for the overhang degree range and wall speed is used") };[m
[32m +        line.label_path = "speed_settings_overhang_speed#speed";[m
[32m +        line.append_option(optgroup->get_option("overhang_1_4_speed"));[m
[32m +        line.append_option(optgroup->get_option("overhang_2_4_speed"));[m
[32m +        line.append_option(optgroup->get_option("overhang_3_4_speed"));[m
[32m +        line.append_option(optgroup->get_option("overhang_4_4_speed"));[m
[32m +        optgroup->append_line(line);[m
[32m +        optgroup->append_separator();[m
[32m +        line = { L("Bridge"), L("Set speed for external and internal bridges") };[m
[32m +        line.append_option(optgroup->get_option("bridge_speed"));[m
[32m +        line.append_option(optgroup->get_option("internal_bridge_speed"));[m
[32m +        optgroup->append_line(line);[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Travel speed"), L"param_travel_speed", 15);[m
[32m +        optgroup->append_single_option_line("travel_speed", "speed_settings_travel");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Acceleration"), L"param_acceleration", 15);[m
[32m +        optgroup->append_single_option_line("default_acceleration", "speed_settings_acceleration#normal-printing");[m
[32m +        optgroup->append_single_option_line("outer_wall_acceleration", "speed_settings_acceleration#outer-wall");[m
[32m +        optgroup->append_single_option_line("inner_wall_acceleration", "speed_settings_acceleration#inner-wall");[m
[32m +        optgroup->append_single_option_line("bridge_acceleration", "speed_settings_acceleration#bridge");[m
[32m +        optgroup->append_single_option_line("sparse_infill_acceleration", "speed_settings_acceleration#sparse-infill");[m
[32m +        optgroup->append_single_option_line("internal_solid_infill_acceleration", "speed_settings_acceleration#internal-solid-infill");[m
[32m +        optgroup->append_single_option_line("initial_layer_acceleration", "speed_settings_acceleration#initial-layer");[m
[32m +        optgroup->append_single_option_line("top_surface_acceleration", "speed_settings_acceleration#top-surface");[m
[32m +        optgroup->append_single_option_line("travel_acceleration", "speed_settings_acceleration#travel");[m
[32m +        optgroup->append_single_option_line("accel_to_decel_enable", "speed_settings_acceleration");[m
[32m +        optgroup->append_single_option_line("accel_to_decel_factor", "speed_settings_acceleration");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Jerk(XY)"), L"param_jerk", 15);[m
[32m +        optgroup->append_single_option_line("default_junction_deviation", "speed_settings_jerk_xy#junction-deviation");[m
[32m +        optgroup->append_single_option_line("default_jerk", "speed_settings_jerk_xy#default");[m
[32m +        optgroup->append_single_option_line("outer_wall_jerk", "speed_settings_jerk_xy#outer-wall");[m
[32m +        optgroup->append_single_option_line("inner_wall_jerk", "speed_settings_jerk_xy#inner-wall");[m
[32m +        optgroup->append_single_option_line("infill_jerk", "speed_settings_jerk_xy#infill");[m
[32m +        optgroup->append_single_option_line("top_surface_jerk", "speed_settings_jerk_xy#top-surface");[m
[32m +        optgroup->append_single_option_line("initial_layer_jerk", "speed_settings_jerk_xy#initial-layer");[m
[32m +        optgroup->append_single_option_line("travel_jerk", "speed_settings_jerk_xy#travel");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Advanced"), L"param_advanced", 15);[m
[32m +        optgroup->append_single_option_line("max_volumetric_extrusion_rate_slope", "speed_settings_advanced");[m
[32m +        optgroup->append_single_option_line("max_volumetric_extrusion_rate_slope_segment_length", "speed_settings_advanced");[m
[32m +        optgroup->append_single_option_line("extrusion_rate_smoothing_external_perimeter_only", "speed_settings_advanced");[m
[32m +[m
[32m +    page = add_options_page(L("Support"), "custom-gcode_support"); // ORCA: icon only visible on placeholders[m
[32m +        optgroup = page->new_optgroup(L("Support"), L"param_support");[m
[32m +        optgroup->append_single_option_line("enable_support", "support_settings_support");[m
[32m +        optgroup->append_single_option_line("support_type", "support_settings_support#type");[m
[32m +        optgroup->append_single_option_line("support_style", "support_settings_support#style");[m
[32m +        optgroup->append_single_option_line("support_threshold_angle", "support_settings_support#threshold-angle");[m
[32m +        optgroup->append_single_option_line("support_threshold_overlap", "support_settings_support#threshold-overlap");[m
[32m +        optgroup->append_single_option_line("raft_first_layer_density", "support_settings_support#initial-layer-density");[m
[32m +        optgroup->append_single_option_line("raft_first_layer_expansion", "support_settings_support#initial-layer-expansion");[m
[32m +        optgroup->append_single_option_line("support_on_build_plate_only", "support_settings_support#on-build-plate-only");[m
[32m +        optgroup->append_single_option_line("support_critical_regions_only", "support_settings_support#support-critical-regions-only");[m
[32m +        optgroup->append_single_option_line("support_remove_small_overhang", "support_settings_support#ignore-small-overhangs");[m
[32m +        //optgroup->append_single_option_line("enforce_support_layers", "support_settings_support");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Raft"), L"param_raft");[m
[32m +        optgroup->append_single_option_line("raft_layers", "support_settings_raft");[m
[32m +        optgroup->append_single_option_line("raft_contact_distance", "support_settings_raft");[m
[32m +        optgroup->append_single_option_line("raft_expansion", "support_settings_raft");[m
[32m +		optgroup->append_single_option_line("raft_advanced_params", "support_settings_raft");[m
[32m +		optgroup->append_single_option_line("raft_base_density", "support_settings_raft");[m
[32m +		optgroup->append_single_option_line("raft_interface_density", "support_settings_raft");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Support filament"), L"param_support_filament");[m
[32m +        optgroup->append_single_option_line("support_filament", "support_settings_filament#base");[m
[32m +        optgroup->append_single_option_line("support_interface_filament", "support_settings_filament#interface");[m
[32m +        optgroup->append_single_option_line("support_interface_not_for_body", "support_settings_filament#avoid-interface-filament-for-base");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Support ironing"), L"param_ironing");[m
[32m +        optgroup->append_single_option_line("support_ironing", "support_settings_ironing");[m
[32m +        optgroup->append_single_option_line("support_ironing_pattern", "support_settings_ironing#pattern");[m
[32m +        optgroup->append_single_option_line("support_ironing_flow", "support_settings_ironing#flow");[m
[32m +        optgroup->append_single_option_line("support_ironing_spacing", "support_settings_ironing#line-spacing");[m
[32m +[m
[32m +        //optgroup = page->new_optgroup(L("Options for support material and raft"));[m
[32m +[m
[32m +        // Support[m
[32m +        optgroup = page->new_optgroup(L("Advanced"), L"param_advanced");[m
[32m +        optgroup->append_single_option_line("support_top_z_distance", "support_settings_advanced#z-distance");[m
[32m +        optgroup->append_single_option_line("support_bottom_z_distance", "support_settings_advanced#z-distance");[m
[32m +        optgroup->append_single_option_line("tree_support_wall_count", "support_settings_advanced#support-wall-loops");[m
[32m +        optgroup->append_single_option_line("support_base_pattern", "support_settings_advanced#base-pattern");[m
[32m +        optgroup->append_single_option_line("support_base_pattern_spacing", "support_settings_advanced#base-pattern-spacing");[m
[32m +        optgroup->append_single_option_line("support_angle", "support_settings_advanced#pattern-angle");[m
[32m +        optgroup->append_single_option_line("support_interface_top_layers", "support_settings_advanced#interface-layers");[m
[32m +        optgroup->append_single_option_line("support_interface_bottom_layers", "support_settings_advanced#interface-layers");[m
[32m +        optgroup->append_single_option_line("support_interface_pattern", "support_settings_advanced#interface-pattern");[m
[32m +        optgroup->append_single_option_line("support_interface_spacing", "support_settings_advanced#interface-spacing");[m
[32m +        optgroup->append_single_option_line("support_bottom_interface_spacing", "support_settings_advanced#interface-spacing");[m
[32m +        optgroup->append_single_option_line("support_expansion", "support_settings_advanced#normal-support-expansion");[m
[32m +        //optgroup->append_single_option_line("support_interface_loop_pattern", "support_settings_advanced");[m
[32m +[m
[32m +        optgroup->append_single_option_line("support_object_xy_distance", "support_settings_advanced#supportobject-xy-distance");[m
[32m +        optgroup->append_single_option_line("support_object_first_layer_gap", "support_settings_advanced#supportobject-first-layer-gap");[m
[32m +        optgroup->append_single_option_line("bridge_no_support", "support_settings_advanced#dont-support-bridges");[m
[32m +        optgroup->append_single_option_line("max_bridge_length", "support_settings_advanced");[m
[32m +        optgroup->append_single_option_line("independent_support_layer_height", "support_settings_advanced#independent-support-layer-height");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Tree supports"), L"param_support_tree");[m
[32m +        optgroup->append_single_option_line("tree_support_tip_diameter", "support_settings_tree#tip-diameter");[m
[32m +        optgroup->append_single_option_line("tree_support_branch_distance", "support_settings_tree#branch-distance");[m
[32m +        optgroup->append_single_option_line("tree_support_branch_distance_organic", "support_settings_tree#branch-distance");[m
[32m +        optgroup->append_single_option_line("tree_support_top_rate", "support_settings_tree#branch-density");[m
[32m +        optgroup->append_single_option_line("tree_support_branch_diameter", "support_settings_tree#branch-diameter");[m
[32m +        optgroup->append_single_option_line("tree_support_branch_diameter_organic", "support_settings_tree#branch-diameter");[m
[32m +        optgroup->append_single_option_line("tree_support_branch_diameter_angle", "support_settings_tree#branch-diameter-angle");[m
[32m +        optgroup->append_single_option_line("tree_support_branch_angle", "support_settings_tree#branch-angle");[m
[32m +        optgroup->append_single_option_line("tree_support_branch_angle_organic", "support_settings_tree#branch-angle");[m
[32m +        optgroup->append_single_option_line("tree_support_angle_slow", "support_settings_tree#preferred-branch-angle");[m
[32m +        optgroup->append_single_option_line("tree_support_auto_brim", "support_settings_tree");[m
[32m +        optgroup->append_single_option_line("tree_support_brim_width", "support_settings_tree");[m
[32m +[m
[32m +    page = add_options_page(L("Multimaterial"), "custom-gcode_multi_material"); // ORCA: icon only visible on placeholders[m
[32m +        optgroup = page->new_optgroup(L("Prime tower"), L"param_tower");[m
[32m +        optgroup->append_single_option_line("enable_prime_tower", "multimaterial_settings_prime_tower");[m
[32m +        optgroup->append_single_option_line("prime_tower_skip_points", "multimaterial_settings_prime_tower");[m
[32m +        optgroup->append_single_option_line("enable_tower_interface_features", "multimaterial_settings_prime_tower");[m
[32m +        optgroup->append_single_option_line("enable_tower_interface_cooldown_during_tower", "multimaterial_settings_prime_tower");[m
[32m +        optgroup->append_single_option_line("prime_tower_enable_framework", "multimaterial_settings_prime_tower");[m
[32m +        optgroup->append_single_option_line("prime_tower_width", "multimaterial_settings_prime_tower#width");[m
[32m +        optgroup->append_single_option_line("prime_volume", "multimaterial_settings_prime_tower");[m
[32m +        optgroup->append_single_option_line("prime_tower_brim_width", "multimaterial_settings_prime_tower#brim-width");[m
[32m +        optgroup->append_single_option_line("prime_tower_infill_gap", "multimaterial_settings_prime_tower");[m
[32m +        optgroup->append_single_option_line("wipe_tower_rotation_angle", "multimaterial_settings_prime_tower#wipe-tower-rotation-angle");[m
[32m +        optgroup->append_single_option_line("wipe_tower_bridging", "multimaterial_settings_prime_tower#maximal-bridging-distance");[m
[32m +        optgroup->append_single_option_line("wipe_tower_extra_spacing", "multimaterial_settings_prime_tower#wipe-tower-purge-lines-spacing");[m
[32m +        optgroup->append_single_option_line("wipe_tower_extra_flow", "multimaterial_settings_prime_tower#extra-flow-for-purge");[m
[32m +        optgroup->append_single_option_line("wipe_tower_max_purge_speed", "multimaterial_settings_prime_tower#maximum-wipe-tower-print-speed");[m
[32m +        optgroup->append_single_option_line("wipe_tower_wall_type", "multimaterial_settings_prime_tower#wall-type");[m
[32m +        optgroup->append_single_option_line("wipe_tower_cone_angle", "multimaterial_settings_prime_tower#stabilization-cone-apex-angle");[m
[32m +        optgroup->append_single_option_line("wipe_tower_extra_rib_length", "multimaterial_settings_prime_tower#extra-rib-length");[m
[32m +        optgroup->append_single_option_line("wipe_tower_rib_width", "multimaterial_settings_prime_tower#rib-width");[m
[32m +        optgroup->append_single_option_line("wipe_tower_fillet_wall", "multimaterial_settings_prime_tower#fillet-wall");[m
[32m +        optgroup->append_single_option_line("wipe_tower_no_sparse_layers", "multimaterial_settings_prime_tower#no-sparse-layers");[m
[32m +        optgroup->append_single_option_line("single_extruder_multi_material_priming", "multimaterial_settings_prime_tower");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Filament for Features"), L"param_filament_for_features");[m
[32m +        optgroup->append_single_option_line("wall_filament", "multimaterial_settings_filament_for_features#walls");[m
[32m +        optgroup->append_single_option_line("sparse_infill_filament", "multimaterial_settings_filament_for_features#infill");[m
[32m +        optgroup->append_single_option_line("solid_infill_filament", "multimaterial_settings_filament_for_features#solid-infill");[m
[32m +        optgroup->append_single_option_line("wipe_tower_filament", "multimaterial_settings_filament_for_features#wipe-tower");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Ooze prevention"), L"param_ooze_prevention");[m
[32m +        optgroup->append_single_option_line("ooze_prevention", "multimaterial_settings_ooze_prevention");[m
[32m +        optgroup->append_single_option_line("standby_temperature_delta", "multimaterial_settings_ooze_prevention#temperature-variation");[m
[32m +        optgroup->append_single_option_line("preheat_time", "multimaterial_settings_ooze_prevention#preheat-time");[m
[32m +        optgroup->append_single_option_line("preheat_steps", "multimaterial_settings_ooze_prevention#preheat-steps");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Flush options"), L"param_flush");[m
[32m +        optgroup->append_single_option_line("flush_into_infill", "multimaterial_settings_flush_options#flush-into-objects-infill");[m
[32m +        optgroup->append_single_option_line("flush_into_objects", "multimaterial_settings_flush_options");[m
[32m +        optgroup->append_single_option_line("flush_into_support", "multimaterial_settings_flush_options#flush-into-objects-support");[m
[32m +        optgroup = page->new_optgroup(L("Advanced"), L"advanced");[m
[32m +        optgroup->append_single_option_line("interlocking_beam", "multimaterial_settings_advanced#interlocking-beam");[m
[32m +        optgroup->append_single_option_line("interface_shells", "multimaterial_settings_advanced#interface-shells");[m
[32m +        optgroup->append_single_option_line("mmu_segmented_region_max_width", "multimaterial_settings_advanced#maximum-width-of-segmented-region");[m
[32m +        optgroup->append_single_option_line("mmu_segmented_region_interlocking_depth", "multimaterial_settings_advanced#interlocking-depth-of-segmented-region");[m
[32m +        optgroup->append_single_option_line("interlocking_beam_width", "multimaterial_settings_advanced#interlocking-beam-width");[m
[32m +        optgroup->append_single_option_line("interlocking_orientation", "multimaterial_settings_advanced#interlocking-direction");[m
[32m +        optgroup->append_single_option_line("interlocking_beam_layer_count", "multimaterial_settings_advanced#interlocking-beam-layers");[m
[32m +        optgroup->append_single_option_line("interlocking_depth", "multimaterial_settings_advanced#interlocking-depth");[m
[32m +        optgroup->append_single_option_line("interlocking_boundary_avoidance", "multimaterial_settings_advanced#interlocking-boundary-avoidance");[m
[32m +[m
[32m +    page = add_options_page(L("Others"), "custom-gcode_other"); // ORCA: icon only visible on placeholders[m
[32m +        optgroup = page->new_optgroup(L("Skirt"), L"param_skirt");[m
[32m +        optgroup->append_single_option_line("skirt_loops", "others_settings_skirt#loops");[m
[32m +        optgroup->append_single_option_line("skirt_type", "others_settings_skirt#type");[m
[32m +        optgroup->append_single_option_line("min_skirt_length", "others_settings_skirt#minimum-extrusion-length");[m
[32m +        optgroup->append_single_option_line("skirt_distance", "others_settings_skirt#distance");[m
[32m +        optgroup->append_single_option_line("skirt_start_angle", "others_settings_skirt#start-point");[m
[32m +        optgroup->append_single_option_line("skirt_speed", "others_settings_skirt#speed");[m
[32m +        optgroup->append_single_option_line("skirt_height", "others_settings_skirt#height");[m
[32m +        optgroup->append_single_option_line("draft_shield", "others_settings_skirt#shield");[m
[32m +        optgroup->append_single_option_line("single_loop_draft_shield", "others_settings_skirt#single-loop-after-first-layer");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Brim"), L"param_adhension");[m
[32m +        optgroup->append_single_option_line("brim_type", "others_settings_brim#type");[m
[32m +        optgroup->append_single_option_line("brim_width", "others_settings_brim#width");[m
[32m +        optgroup->append_single_option_line("brim_object_gap", "others_settings_brim#brim-object-gap");[m
[32m +        optgroup->append_single_option_line("brim_use_efc_outline", "others_settings_brim#brim-use-efc-outline");[m
[32m +        optgroup->append_single_option_line("combine_brims", "others_settings_brim#combine-brims");[m
[32m +        optgroup->append_single_option_line("brim_ears_max_angle", "others_settings_brim#ear-max-angle");[m
[32m +        optgroup->append_single_option_line("brim_ears_detection_length", "others_settings_brim#ear-detection-radius");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Special mode"), L"param_special");[m
[32m +        optgroup->append_single_option_line("slicing_mode", "others_settings_special_mode#slicing-mode");[m
[32m +        optgroup->append_single_option_line("print_sequence", "others_settings_special_mode#print-sequence");[m
[32m +        optgroup->append_single_option_line("print_order", "others_settings_special_mode#intra-layer-order");[m
[32m +        optgroup->append_single_option_line("spiral_mode", "others_settings_special_mode#spiral-vase");[m
[32m +        optgroup->append_single_option_line("spiral_mode_smooth", "others_settings_special_mode#smooth-spiral");[m
[32m +        optgroup->append_single_option_line("spiral_mode_max_xy_smoothing", "others_settings_special_mode#max-xy-smoothing");[m
[32m +        optgroup->append_single_option_line("spiral_starting_flow_ratio", "others_settings_special_mode#spiral-starting-flow-ratio");[m
[32m +        optgroup->append_single_option_line("spiral_finishing_flow_ratio", "others_settings_special_mode#spiral-finishing-flow-ratio");[m
[32m +[m
[32m +        optgroup->append_single_option_line("timelapse_type", "others_settings_special_mode#timelapse");[m
[32m +        optgroup->append_single_option_line("enable_wrapping_detection");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("Fuzzy Skin"), L"fuzzy_skin");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin", "others_settings_fuzzy_skin");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_mode", "others_settings_fuzzy_skin#fuzzy-skin-mode");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_noise_type", "others_settings_fuzzy_skin#noise-type");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_point_distance", "others_settings_fuzzy_skin#point-distance");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_thickness", "others_settings_fuzzy_skin#skin-thickness");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_scale", "others_settings_fuzzy_skin#skin-feature-size");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_octaves", "others_settings_fuzzy_skin#skin-noise-octaves");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_persistence", "others_settings_fuzzy_skin#skin-noise-persistence");[m
[32m +        optgroup->append_single_option_line("fuzzy_skin_first_layer", "others_settings_fuzzy_skin#apply-fuzzy-skin-to-first-layer");[m
[32m +[m
[32m +        optgroup = page->new_optgroup(L("G-code output"), L"param_gcode");[m
[32m +        optgroup->append_single_option_line("reduce_infill_retraction", "others_settings_g_code_output#reduce-infill-retraction");[m
[32m +        optgroup->append_single_option_line("gcode_add_line_number", "others_settings_g_code_output#add-line-number");[m
[32m +        optgroup->append_single_option_line("gcode_comments", "others_settings_g_code_output#verbose-g-code");[m
[32m +        optgroup->append_single_option_line("gcode_label_objects", "others_settings_g_code_output#label-objects");[m
[32m +        optgroup->append_single_option_line("exclude_object", "others_settings_g_code_output#exclude-objects");[m
[32m +        option = optgroup->get_option("filename_format");[m
[32m +        // option.opt.full_width = true;[m
[32m +        option.opt.is_code = true;[m
[32m +        option.opt.multiline = true;[m
[32m +        // option.opt.height = 5;[m
[32m +        optgroup->append_single_option_line(option, "others_settings_g_code_output#filename-format");[m
  [m
[31m -        optgroup = page->new_optgroup(L("Post-processing scripts"), 0);[m
[32m +        optgroup = page->new_optgroup(L("Post-processing Scripts"), L"param_gcode", 0);[m
          option = optgroup->get_option("post_process");[m
          option.opt.full_width = true;[m
[31m -        option.opt.height = 5;//50;[m
[31m -        optgroup->append_single_option_line(option);[m
[32m +        option.opt.is_code = true;[m
[32m +        option.opt.height = 15;[m
[32m +        optgroup->append_single_option_line(option, "others_settings_post_processing_scripts");[m
  [m
[31m -    page = add_options_page(L("Notes"), "note.png");[m
[31m -        optgroup = page->new_optgroup(L("Notes"), 0);[m
[32m +        optgroup = page->new_optgroup(L("Notes"), "note", 0);[m
          option = optgroup->get_option("notes");[m
          option.opt.full_width = true;[m
          option.opt.height = 25;//250;[m
