;import ui settings
(run 'apps/ui.lisp)

(defq window (call slot_create_window nil window_flag_close)
	display (call slot_create_label nil)
	flow (call slot_create_flow nil)
	grid (call slot_create_grid nil))

(call slot_set_title window "Calculator")
(eval (list defq 'flow_flags (bit-or flow_flag_down flow_flag_fillw flow_flag_lasth)) flow)
(eval (list defq 'grid_width 4 'grid_height 4 'color 0xffffff00
	'font (call slot_create_font nil "fonts/OpenSans-Regular.ttf" 42)) grid)
(eval (list defq 'text "0" 'color 0xffffffff 'flow_flags flow_flag_align_hright
	'font (call slot_create_font nil "fonts/OpenSans-Regular.ttf" 24)) display)
(each (lambda (_)
	(defq button (call slot_create_button nil))
	(eval (list defq 'text (if (eql _ "C") "AC" _)
		'flow_flags (bit-or flow_flag_align_hcenter flow_flag_align_vcenter)) button)
	(call slot_connect_click button 1)
	(call slot_add_child grid button)) "789/456*123-0=C+")
(call slot_add_child window flow)
(call slot_add_child flow display)
(call slot_add_child flow grid)
(call slot_connect_close window 0)
(bind '(w h) (call slot_pref_size window))
(call slot_change window 920 48 w h)
(call slot_gui_add window)

(defq id t)
(while id
	(cond
		((ge (setq id (read-long ev_msg_target_id (defq msg (mail-mymail)))) 1)
			nil)
		((eq id 0)
			(setq id nil))
		(t (call slot_event window msg))))