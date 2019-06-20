﻿// Decompiled by AS3 Sorcerer 3.16
// http://www.as3sorcerer.com/

//fl.controls.BaseButton

package fl.controls
{
    import fl.core.UIComponent;
    import flash.utils.Timer;
    import flash.display.DisplayObject;
    import flash.events.TimerEvent;
    import fl.events.ComponentEvent;
    import fl.core.InvalidationType;
    import flash.events.MouseEvent;

    public class BaseButton extends UIComponent 
    {

        private static var defaultStyles:Object = {
            "upSkin":"Button_upSkin",
            "downSkin":"Button_downSkin",
            "overSkin":"Button_overSkin",
            "disabledSkin":"Button_disabledSkin",
            "selectedDisabledSkin":"Button_selectedDisabledSkin",
            "selectedUpSkin":"Button_selectedUpSkin",
            "selectedDownSkin":"Button_selectedDownSkin",
            "selectedOverSkin":"Button_selectedOverSkin",
            "focusRectSkin":null,
            "focusRectPadding":null,
            "repeatDelay":500,
            "repeatInterval":35
        };

        protected var pressTimer:Timer;
        protected var _autoRepeat:Boolean = false;
        protected var _selected:Boolean = false;
        protected var background:DisplayObject;
        private var unlockedMouseState:String;
        protected var mouseState:String;
        private var _mouseStateLocked:Boolean = false;

        public function BaseButton()
        {
            buttonMode = true;
            mouseChildren = false;
            useHandCursor = false;
            setupMouseEvents();
            setMouseState("up");
            pressTimer = new Timer(1, 0);
            pressTimer.addEventListener(TimerEvent.TIMER, buttonDown, false, 0, true);
        }

        public static function getStyleDefinition():Object
        {
            return (defaultStyles);
        }


        override public function get enabled():Boolean
        {
            return (super.enabled);
        }

        protected function startPress():void
        {
            if (_autoRepeat)
            {
                pressTimer.delay = Number(getStyleValue("repeatDelay"));
                pressTimer.start();
            };
            dispatchEvent(new ComponentEvent(ComponentEvent.BUTTON_DOWN, true));
        }

        override protected function draw():void
        {
            if (isInvalid(InvalidationType.STYLES, InvalidationType.STATE))
            {
                drawBackground();
                invalidate(InvalidationType.SIZE, false);
            };
            if (isInvalid(InvalidationType.SIZE))
            {
                drawLayout();
            };
            super.draw();
        }

        protected function drawLayout():void
        {
            background.width = width;
            background.height = height;
        }

        override public function set enabled(_arg_1:Boolean):void
        {
            super.enabled = _arg_1;
            mouseEnabled = _arg_1;
        }

        public function set autoRepeat(_arg_1:Boolean):void
        {
            _autoRepeat = _arg_1;
        }

        protected function mouseEventHandler(_arg_1:MouseEvent):void
        {
            if (_arg_1.type == MouseEvent.MOUSE_DOWN)
            {
                setMouseState("down");
                startPress();
            } else
            {
                if ((((_arg_1.type == MouseEvent.ROLL_OVER)) || ((_arg_1.type == MouseEvent.MOUSE_UP))))
                {
                    setMouseState("over");
                    endPress();
                } else
                {
                    if (_arg_1.type == MouseEvent.ROLL_OUT)
                    {
                        setMouseState("up");
                        endPress();
                    };
                };
            };
        }

        protected function drawBackground():void
        {
            var _local_1:String = ((enabled) ? mouseState : "disabled");
            if (selected)
            {
                _local_1 = (("selected" + _local_1.substr(0, 1).toUpperCase()) + _local_1.substr(1));
            };
            _local_1 = (_local_1 + "Skin");
            var _local_2:DisplayObject = background;
            background = getDisplayObjectInstance(getStyleValue(_local_1));
            addChildAt(background, 0);
            if (((!((_local_2 == null))) && (!((_local_2 == background)))))
            {
                removeChild(_local_2);
            };
        }

        public function get selected():Boolean
        {
            return (_selected);
        }

        protected function setupMouseEvents():void
        {
            addEventListener(MouseEvent.ROLL_OVER, mouseEventHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_DOWN, mouseEventHandler, false, 0, true);
            addEventListener(MouseEvent.MOUSE_UP, mouseEventHandler, false, 0, true);
            addEventListener(MouseEvent.ROLL_OUT, mouseEventHandler, false, 0, true);
        }

        protected function endPress():void
        {
            pressTimer.reset();
        }

        public function set mouseStateLocked(_arg_1:Boolean):void
        {
            _mouseStateLocked = _arg_1;
            if (_arg_1 == false)
            {
                setMouseState(unlockedMouseState);
            } else
            {
                unlockedMouseState = mouseState;
            };
        }

        public function get autoRepeat():Boolean
        {
            return (_autoRepeat);
        }

        public function set selected(_arg_1:Boolean):void
        {
            if (_selected == _arg_1)
            {
                return;
            };
            _selected = _arg_1;
            invalidate(InvalidationType.STATE);
        }

        protected function buttonDown(_arg_1:TimerEvent):void
        {
            if (!_autoRepeat)
            {
                endPress();
                return;
            };
            if (pressTimer.currentCount == 1)
            {
                pressTimer.delay = Number(getStyleValue("repeatInterval"));
            };
            dispatchEvent(new ComponentEvent(ComponentEvent.BUTTON_DOWN, true));
        }

        public function setMouseState(_arg_1:String):void
        {
            if (_mouseStateLocked)
            {
                unlockedMouseState = _arg_1;
                return;
            };
            if (mouseState == _arg_1)
            {
                return;
            };
            mouseState = _arg_1;
            invalidate(InvalidationType.STATE);
        }


    }
}//package fl.controls

