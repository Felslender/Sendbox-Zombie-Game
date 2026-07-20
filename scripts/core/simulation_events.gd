class_name SimulationEvents
extends Node

signal metrics_changed(metrics: Dictionary)
signal feedback_requested(message: String, is_error: bool)
signal tool_changed(tool_name: String)
signal simulation_reset_requested
