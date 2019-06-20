// Decompiled by AS3 Sorcerer 3.16
// http://www.as3sorcerer.com/

//fl.core.UIComponent

package fl.core
{
    import flash.display.Sprite;
    import flash.text.TextFormat;
    import flash.text.TextFormatAlign;
    import flash.utils.Dictionary;
    import flash.text.TextField;
    import fl.managers.IFocusManagerComponent;
    import flash.display.DisplayObject;
    import fl.managers.StyleManager;
    import flash.events.FocusEvent;
    import flash.events.KeyboardEvent;
    import flash.events.Event;
    import flash.utils.getQualifiedClassName;
    import flash.display.InteractiveObject;
    import flash.system.IME;
    import flash.system.IMEConversionMode;
    import fl.managers.IFocusManager;
    import fl.events.ComponentEvent;
    import flash.utils.getDefinitionByName;
    import fl.managers.FocusManager;

    public class UIComponent extends Sprite 
    {

        public static var inCallLaterPhase:Boolean = false;
        private static var defaultStyles:Object = {
            "focusRectSkin":"focusRectSkin",
            "focusRectPadding":2,
            "textFormat":new TextFormat("_sans", 11, 0, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0),
            "disabledTextFormat":new TextFormat("_sans", 11, 0x999999, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0),
            "defaultTextFormat":new TextFormat("_sans", 11, 0, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0),
            "defaultDisabledTextFormat":new TextFormat("_sans", 11, 0x999999, false, false, false, "", "", TextFormatAlign.LEFT, 0, 0, 0, 0)
        };
        private static var focusManagers:Dictionary = new Dictionary(false);
        public static var createAccessibilityImplementation:Function;

        protected var _x:Number;
        protected var _enabled:Boolean = true;
        protected var callLaterMethods:Dictionary;
        private var _mouseFocusEnabled:Boolean = true;
        private var tempText:TextField;
        private var _focusEnabled:Boolean = true;
        protected var startHeight:Number;
        protected var _height:Number;
        protected var invalidateFlag:Boolean = false;
        protected var _oldIMEMode:String = null;
        protected var _inspector:Boolean = false;
        protected var startWidth:Number;
        public var focusTarget:IFocusManagerComponent;
        protected var errorCaught:Boolean = false;
        protected var invalidHash:Object;
        protected var sharedStyles:Object;
        protected var uiFocusRect:DisplayObject;
        protected var isLivePreview:Boolean = false;
        protected var _imeMode:String = null;
        protected var _width:Number;
        protected var instanceStyles:Object;
        public var version:String = "3.0.0.16";
        protected var isFocused:Boolean = false;
        protected var _y:Number;

        public function UIComponent()
        {
            instanceStyles = {};
            sharedStyles = {};
            invalidHash = {};
            callLaterMethods = new Dictionary();
            StyleManager.registerInstance(this);
            configUI();
            invalidate(InvalidationType.ALL);
            tabEnabled = (this is IFocusManagerComponent);
            focusRect = false;
            if (tabEnabled)
            {
                addEventListener(FocusEvent.FOCUS_IN, focusInHandler);
                addEventListener(FocusEvent.FOCUS_OUT, focusOutHandler);
                addEventListener(KeyboardEvent.KEY_DOWN, keyDownHandler);
                addEventListener(KeyboardEvent.KEY_UP, keyUpHandler);
            };
            initializeFocusManager();
            addEventListener(Event.ENTER_FRAME, hookAccessibility, false, 0, true);
        }

        public static function getStyleDefinition():Object
        {
            return (defaultStyles);
        }

        public static function mergeStyles(... _args):Object
        {
            var _local_5:Object;
            var _local_6:String;
            var _local_2:Object = {};
            var _local_3:uint = _args.length;
            var _local_4:uint;
            while (_local_4 < _local_3)
            {
                _local_5 = _args[_local_4];
                for (_local_6 in _local_5)
                {
                    if (_local_2[_local_6] == null)
                    {
                        _local_2[_local_6] = _args[_local_4][_local_6];
                    };
                };
                _local_4++;
            };
            return (_local_2);
        }


        public function getStyle(_arg_1:String):Object
        {
            return (instanceStyles[_arg_1]);
        }

        protected function checkLivePreview():Boolean
        {
            var className:String;
            if (parent == null)
            {
                return (false);
            };
            try
            {
                className = getQualifiedClassName(parent);
            } catch(e:Error)
            {
            };
            return ((className == "fl.livepreview::LivePreviewParent"));
        }

        private function callLaterDispatcher(_arg_1:Event):void
        {
            var _local_3:Object;
            if (_arg_1.type == Event.ADDED_TO_STAGE)
            {
                removeEventListener(Event.ADDED_TO_STAGE, callLaterDispatcher);
                stage.addEventListener(Event.RENDER, callLaterDispatcher, false, 0, true);
                stage.invalidate();
                return;
            };
            _arg_1.target.removeEventListener(Event.RENDER, callLaterDispatcher);
            if (stage == null)
            {
                addEventListener(Event.ADDED_TO_STAGE, callLaterDispatcher, false, 0, true);
                return;
            };
            inCallLaterPhase = true;
            var _local_2:Dictionary = callLaterMethods;
            for (_local_3 in _local_2)
            {
                (_local_3());
                delete _local_2[_local_3];
            };
            inCallLaterPhase = false;
        }

        protected function validate():void
        {
            invalidHash = {};
        }

        protected function focusOutHandler(_arg_1:FocusEvent):void
        {
            if (isOurFocus((_arg_1.target as DisplayObject)))
            {
                drawFocus(false);
                isFocused = false;
            };
        }

        public function set mouseFocusEnabled(_arg_1:Boolean):void
        {
            _mouseFocusEnabled = _arg_1;
        }

        public function getFocus():InteractiveObject
        {
            if (stage)
            {
                return (stage.focus);
            };
            return (null);
        }

        override public function get height():Number
        {
            return (_height);
        }

        private function addedHandler(_arg_1:Event):void
        {
            removeEventListener("addedToStage", addedHandler);
            initializeFocusManager();
        }

        protected function getStyleValue(_arg_1:String):Object
        {
            return ((((instanceStyles[_arg_1])==null) ? sharedStyles[_arg_1] : instanceStyles[_arg_1]));
        }

        public function invalidate(_arg_1:String="all", _arg_2:Boolean=true):void
        {
            invalidHash[_arg_1] = true;
            if (_arg_2)
            {
                this.callLater(draw);
            };
        }

        protected function isOurFocus(_arg_1:DisplayObject):Boolean
        {
            return ((_arg_1 == this));
        }

        public function get enabled():Boolean
        {
            return (_enabled);
        }

        protected function getScaleX():Number
        {
            return (super.scaleX);
        }

        protected function getScaleY():Number
        {
            return (super.scaleY);
        }

        public function get focusEnabled():Boolean
        {
            return (_focusEnabled);
        }

        protected function afterComponentParameters():void
        {
        }

        override public function get scaleY():Number
        {
            return ((height / startHeight));
        }

        protected function setIMEMode(enabled:Boolean)
        {
            if (_imeMode != null)
            {
                if (enabled)
                {
                    IME.enabled = true;
                    _oldIMEMode = IME.conversionMode;
                    try
                    {
                        if (((!(errorCaught)) && (!((IME.conversionMode == IMEConversionMode.UNKNOWN)))))
                        {
                            IME.conversionMode = _imeMode;
                        };
                        errorCaught = false;
                    } catch(e:Error)
                    {
                        errorCaught = true;
                        throw (new Error(("IME mode not supported: " + _imeMode)));
                    };
                } else
                {
                    if (((!((IME.conversionMode == IMEConversionMode.UNKNOWN))) && (!((_oldIMEMode == IMEConversionMode.UNKNOWN)))))
                    {
                        IME.conversionMode = _oldIMEMode;
                    };
                    IME.enabled = false;
                };
            };
        }

        protected function draw():void
        {
            if (isInvalid(InvalidationType.SIZE, InvalidationType.STYLES))
            {
                if (((isFocused) && (focusManager.showFocusIndicator)))
                {
                    drawFocus(true);
                };
            };
            validate();
        }

        override public function set height(_arg_1:Number):void
        {
            if (_height == _arg_1)
            {
                return;
            };
            setSize(width, _arg_1);
        }

        protected function configUI():void
        {
            isLivePreview = checkLivePreview();
            var _local_1:Number = rotation;
            rotation = 0;
            var _local_2:Number = super.width;
            var _local_3:Number = super.height;
            var _local_4:int = 1;
            super.scaleY = _local_4;
            super.scaleX = _local_4;
            setSize(_local_2, _local_3);
            move(super.x, super.y);
            rotation = _local_1;
            startWidth = _local_2;
            startHeight = _local_3;
            if (numChildren > 0)
            {
                removeChildAt(0);
            };
        }

        protected function setScaleY(_arg_1:Number):void
        {
            super.scaleY = _arg_1;
        }

        override public function get scaleX():Number
        {
            return ((width / startWidth));
        }

        protected function setScaleX(_arg_1:Number):void
        {
            super.scaleX = _arg_1;
        }

        private function initializeFocusManager():void
        {
            if (stage == null)
            {
                addEventListener(Event.ADDED_TO_STAGE, addedHandler, false, 0, true);
            } else
            {
                createFocusManager();
            };
        }

        protected function keyDownHandler(_arg_1:KeyboardEvent):void
        {
        }

        public function set focusManager(_arg_1:IFocusManager):void
        {
            UIComponent.focusManagers[this] = _arg_1;
        }

        public function clearStyle(_arg_1:String):void
        {
            setStyle(_arg_1, null);
        }

        protected function isInvalid(_arg_1:String, ... _args):Boolean
        {
            if (((invalidHash[_arg_1]) || (invalidHash[InvalidationType.ALL])))
            {
                return (true);
            };
            while (_args.length > 0)
            {
                if (invalidHash[_args.pop()])
                {
                    return (true);
                };
            };
            return (false);
        }

        public function setStyle(_arg_1:String, _arg_2:Object):void
        {
            if ((((instanceStyles[_arg_1] === _arg_2)) && (!((_arg_2 is TextFormat)))))
            {
                return;
            };
            instanceStyles[_arg_1] = _arg_2;
            invalidate(InvalidationType.STYLES);
        }

        override public function get visible():Boolean
        {
            return (super.visible);
        }

        protected function focusInHandler(_arg_1:FocusEvent):void
        {
            var _local_2:IFocusManager;
            if (isOurFocus((_arg_1.target as DisplayObject)))
            {
                _local_2 = focusManager;
                if (((_local_2) && (_local_2.showFocusIndicator)))
                {
                    drawFocus(true);
                    isFocused = true;
                };
            };
        }

        public function get componentInspectorSetting():Boolean
        {
            return (_inspector);
        }

        override public function get x():Number
        {
            return (((isNaN(_x)) ? super.x : _x));
        }

        override public function get y():Number
        {
            return (((isNaN(_y)) ? super.y : _y));
        }

        public function set enabled(_arg_1:Boolean):void
        {
            if (_arg_1 == _enabled)
            {
                return;
            };
            _enabled = _arg_1;
            invalidate(InvalidationType.STATE);
        }

        public function setSize(_arg_1:Number, _arg_2:Number):void
        {
            _width = _arg_1;
            _height = _arg_2;
            invalidate(InvalidationType.SIZE);
            dispatchEvent(new ComponentEvent(ComponentEvent.RESIZE, false));
        }

        protected function keyUpHandler(_arg_1:KeyboardEvent):void
        {
        }

        public function setSharedStyle(_arg_1:String, _arg_2:Object):void
        {
            if ((((sharedStyles[_arg_1] === _arg_2)) && (!((_arg_2 is TextFormat)))))
            {
                return;
            };
            sharedStyles[_arg_1] = _arg_2;
            if (instanceStyles[_arg_1] == null)
            {
                invalidate(InvalidationType.STYLES);
            };
        }

        public function set focusEnabled(_arg_1:Boolean):void
        {
            _focusEnabled = _arg_1;
        }

        override public function set width(_arg_1:Number):void
        {
            if (_width == _arg_1)
            {
                return;
            };
            setSize(_arg_1, height);
        }

        public function setFocus():void
        {
            if (stage)
            {
                stage.focus = this;
            };
        }

        override public function set scaleX(_arg_1:Number):void
        {
            setSize((startWidth * _arg_1), height);
        }

        public function get mouseFocusEnabled():Boolean
        {
            return (_mouseFocusEnabled);
        }

        override public function set scaleY(_arg_1:Number):void
        {
            setSize(width, (startHeight * _arg_1));
        }

        protected function getDisplayObjectInstance(skin:Object):DisplayObject
        {
            var classDef:Object;
            if ((skin is Class))
            {
                return ((new (skin)() as DisplayObject));
            };
            if ((skin is DisplayObject))
            {
                (skin as DisplayObject).x = 0;
                (skin as DisplayObject).y = 0;
                return ((skin as DisplayObject));
            };
            try
            {
                classDef = getDefinitionByName(skin.toString());
            } catch(e:Error)
            {
                try
                {
                    classDef = (loaderInfo.applicationDomain.getDefinition(skin.toString()) as Object);
                } catch(e:Error)
                {
                };
            };
            if (classDef == null)
            {
                return (null);
            };
            return ((new (classDef)() as DisplayObject));
        }

        protected function copyStylesToChild(_arg_1:UIComponent, _arg_2:Object):void
        {
            var _local_3:String;
            for (_local_3 in _arg_2)
            {
                _arg_1.setStyle(_local_3, getStyleValue(_arg_2[_local_3]));
            };
        }

        protected function initializeAccessibility():void
        {
            if (UIComponent.createAccessibilityImplementation != null)
            {
                UIComponent.createAccessibilityImplementation(this);
            };
        }

        public function get focusManager():IFocusManager
        {
            var _local_1:DisplayObject = this;
            while (_local_1)
            {
                if (UIComponent.focusManagers[_local_1] != null)
                {
                    return (IFocusManager(UIComponent.focusManagers[_local_1]));
                };
                _local_1 = _local_1.parent;
            };
            return (null);
        }

        override public function get width():Number
        {
            return (_width);
        }

        protected function beforeComponentParameters():void
        {
        }

        protected function callLater(_arg_1:Function):void
        {
            if (inCallLaterPhase)
            {
                return;
            };
            callLaterMethods[_arg_1] = true;
            if (stage != null)
            {
                stage.addEventListener(Event.RENDER, callLaterDispatcher, false, 0, true);
                stage.invalidate();
            } else
            {
                addEventListener(Event.ADDED_TO_STAGE, callLaterDispatcher, false, 0, true);
            };
        }

        public function move(_arg_1:Number, _arg_2:Number):void
        {
            _x = _arg_1;
            _y = _arg_2;
            super.x = Math.round(_arg_1);
            super.y = Math.round(_arg_2);
            dispatchEvent(new ComponentEvent(ComponentEvent.MOVE));
        }

        public function validateNow():void
        {
            invalidate(InvalidationType.ALL, false);
            draw();
        }

        override public function set visible(_arg_1:Boolean):void
        {
            if (super.visible == _arg_1)
            {
                return;
            };
            super.visible = _arg_1;
            var _local_2:String = ((_arg_1) ? ComponentEvent.SHOW : ComponentEvent.HIDE);
            dispatchEvent(new ComponentEvent(_local_2, true));
        }

        protected function createFocusManager():void
        {
            if (focusManagers[stage] == null)
            {
                focusManagers[stage] = new FocusManager(stage);
            };
        }

        protected function hookAccessibility(_arg_1:Event):void
        {
            removeEventListener(Event.ENTER_FRAME, hookAccessibility);
            initializeAccessibility();
        }

        public function set componentInspectorSetting(_arg_1:Boolean):void
        {
            _inspector = _arg_1;
            if (_inspector)
            {
                beforeComponentParameters();
            } else
            {
                afterComponentParameters();
            };
        }

        override public function set y(_arg_1:Number):void
        {
            move(_x, _arg_1);
        }

        public function drawFocus(_arg_1:Boolean):void
        {
            var _local_2:Number;
            isFocused = _arg_1;
            if (((!((uiFocusRect == null))) && (contains(uiFocusRect))))
            {
                removeChild(uiFocusRect);
                uiFocusRect = null;
            };
            if (_arg_1)
            {
                uiFocusRect = (getDisplayObjectInstance(getStyleValue("focusRectSkin")) as Sprite);
                if (uiFocusRect == null)
                {
                    return;
                };
                _local_2 = Number(getStyleValue("focusRectPadding"));
                uiFocusRect.x = -(_local_2);
                uiFocusRect.y = -(_local_2);
                uiFocusRect.width = (width + (_local_2 * 2));
                uiFocusRect.height = (height + (_local_2 * 2));
                addChildAt(uiFocusRect, 0);
            };
        }

        override public function set x(_arg_1:Number):void
        {
            move(_arg_1, _y);
        }

        public function drawNow():void
        {
            draw();
        }


    }
}//package fl.core

