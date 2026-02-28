GODOT := $(HOME)/.local/share/Steam/steamapps/common/Godot Engine/godot.x11.opt.tools.64
PROJECT := /home/tom/src/boxx

.PHONY: start restart stop

start:
	"$(GODOT)" --path $(PROJECT) &

restart:
	ps aux | grep godot | grep -v grep | awk '{print $$2}' | xargs kill 2>/dev/null; sleep 1
	"$(GODOT)" --path $(PROJECT) &

stop:
	ps aux | grep godot | grep -v grep | awk '{print $$2}' | xargs kill 2>/dev/null
