var __extends = (this && this.__extends) || (function () {
    var extendStatics = Object.setPrototypeOf ||
        ({ __proto__: [] } instanceof Array && function (d, b) { d.__proto__ = b; }) ||
        function (d, b) { for (var p in b) if (b.hasOwnProperty(p)) d[p] = b[p]; };
    return function (d, b) {
        extendStatics(d, b);
        function __() { this.constructor = d; }
        d.prototype = b === null ? Object.create(b) : (__.prototype = b.prototype, new __());
    };
})();
var src;
(function (src) {
    var CustomScaleManager = (function () {
        function CustomScaleManager() {
        }
        CustomScaleManager.update = function (newWidth, newHeight) {
            CustomScaleManager.WIDTH = newWidth;
            CustomScaleManager.HEIGHT = newHeight;
            var newRatio = newWidth / newHeight;
            if (newRatio >= CustomScaleManager.ORIGINAL_RATIO) {
                CustomScaleManager.SCALE_X = CustomScaleManager.SCALE_Y = newHeight / CustomScaleManager.ORIGINAL_HEIGHT;
            }
            else {
                CustomScaleManager.SCALE_X = CustomScaleManager.SCALE_Y = newWidth / CustomScaleManager.ORIGINAL_WIDTH;
            }
            src.WindowManager.instance.resize();
        };
        CustomScaleManager.reset = function () {
            var elems = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                elems[_i] = arguments[_i];
            }
            for (var i = 0; i < elems.length; i++) {
                if (elems[i]) {
                    CustomScaleManager.rescale(elems[i]);
                    CustomScaleManager.reflow(elems[i]);
                }
                else {
                    // throw new Error("Wrong element");
                }
            }
        };
        CustomScaleManager.reflow = function (element) {
            if (!element["nativePosition"]) {
                element["nativePosition"] = new PIXI.Point(element.position.x / CustomScaleManager.ORIGINAL_WIDTH, element.position.y / CustomScaleManager.ORIGINAL_HEIGHT);
            }
            if (!element["deltaPosition"]) {
                element["deltaPosition"] = new PIXI.Point(0, 0);
            }
            element.position.set(element["nativePosition"].x * CustomScaleManager.WIDTH + element["deltaPosition"].x * CustomScaleManager.SCALE_X, element["nativePosition"].y * CustomScaleManager.HEIGHT + element["deltaPosition"].y * CustomScaleManager.SCALE_Y);
        };
        CustomScaleManager.rescale = function (element) {
            if (!element["nativeScale"]) {
                element["nativeScale"] = element.scale.clone();
            }
            if (element["fitWidth"]) {
                element.scale.set(CustomScaleManager.WIDTH / CustomScaleManager.ORIGINAL_WIDTH, CustomScaleManager.WIDTH / CustomScaleManager.ORIGINAL_WIDTH);
                return;
            }
            if (element["fitHeight"]) {
                element.scale.set(CustomScaleManager.HEIGHT / CustomScaleManager.ORIGINAL_HEIGHT, CustomScaleManager.HEIGHT / CustomScaleManager.ORIGINAL_HEIGHT);
                return;
            }
            element.scale.set(element["nativeScale"].x * CustomScaleManager.SCALE_X, element["nativeScale"].y * CustomScaleManager.SCALE_Y);
        };
        CustomScaleManager.setPosition = function (element, px, py, dx, dy) {
            if (dx === void 0) { dx = 0; }
            if (dy === void 0) { dy = 0; }
            if (!element["nativePosition"]) {
                element["nativePosition"] = new PIXI.Point(px, py);
            }
            if (!element["deltaPosition"]) {
                element["deltaPosition"] = new PIXI.Point(dx, dy);
            }
            CustomScaleManager.reflow(element);
        };
        CustomScaleManager.fitWidth = function (element) {
            element["fitWidth"] = true;
        };
        CustomScaleManager.fitHeight = function (element) {
            element["fitHeight"] = true;
        };
        CustomScaleManager.minX = function () {
            return 0;
        };
        CustomScaleManager.maxX = function () {
            return 1;
        };
        CustomScaleManager.centerX = function () {
            return 0.5;
        };
        CustomScaleManager.minY = function () {
            return 0;
        };
        CustomScaleManager.maxY = function () {
            return 1;
        };
        CustomScaleManager.centerY = function () {
            return 0.5;
        };
        CustomScaleManager.ORIGINAL_WIDTH = 640;
        CustomScaleManager.ORIGINAL_HEIGHT = 960;
        CustomScaleManager.WIDTH = 640;
        CustomScaleManager.HEIGHT = 960;
        CustomScaleManager.SCALE_X = 1;
        CustomScaleManager.SCALE_Y = 1;
        CustomScaleManager.ORIGINAL_RATIO = CustomScaleManager.ORIGINAL_WIDTH / CustomScaleManager.ORIGINAL_HEIGHT;
        return CustomScaleManager;
    }());
    src.CustomScaleManager = CustomScaleManager;
})(src || (src = {}));
var src;
(function (src) {
    var RenderUtils = (function () {
        function RenderUtils() {
        }
        RenderUtils.detectRenderMode = function () {
            var isIE = window.navigator.userAgent.indexOf('MSIE ') > 0 || window.navigator.userAgent.indexOf('Trident/') > 0;
            var isFirefox = navigator.userAgent.toLowerCase().indexOf('firefox') > -1;
            var bestRenderMode = isIE || isFirefox ? Phaser.CANVAS : Phaser.AUTO;
            return bestRenderMode;
        };
        return RenderUtils;
    }());
    src.RenderUtils = RenderUtils;
})(src || (src = {}));
///<reference path="scale/CustomScaleManager.ts"/>
///<reference path="utils/RenderUtils.ts"/>
var src;
(function (src) {
    var App = (function (_super) {
        __extends(App, _super);
        function App() {
            var _this = _super.call(this, App.gameConfig) || this;
            App.instance = _this;
            game = _this;
            _this.state.add('Boot', src.Boot, false);
            _this.state.add('Preloader', src.Preloader, false);
            _this.state.add('MainMenu', src.MainMenu, false);
            _this.state.add('LevelsMap', src.LevelsMap, false);
            _this.state.add('Level', src.Level, false);
            _this.state.start('Boot');
            return _this;
        }
        App.prototype.navigateToSponsor = function () {
            window.famobi.moreGamesLink();
        };
        App.prototype.showAd = function (timeout) {
            return false;
        };
        App.prototype.pauseGame = function () {
            this.paused = true;
        };
        App.prototype.unpauseGame = function () {
            if (isPageVisible && !adIsShowing) {
                this.paused = false;
            }
        };
        App.gameConfig = {
            width: src.CustomScaleManager.ORIGINAL_WIDTH,
            height: src.CustomScaleManager.ORIGINAL_HEIGHT,
            renderer: src.RenderUtils.detectRenderMode(),
            transparent: true
        };
        return App;
    }(Phaser.Game));
    src.App = App;
})(src || (src = {}));
var debugLog = [];
var game;
var isPageVisible = false;
var adIsShowing = false;

//famobi pause/resume requests
window['famobi_onPauseRequested'] = function () {
    window.famobi_sound = window.game.sound.masterGain.gain.value;
    window.game.sound.masterGain.gain.value = 0;
    window.game.paused = true;
    window.famobi_ad = true;
}.bind(this);
window['famobi_onResumeRequested'] = function () {
    window.famobi_ad = false;
    window.game.paused = false;
    window.game.sound.masterGain.gain.value = window.famobi_sound;
};

//visiblity
var hidden, visibilityChange;
if (typeof document.hidden !== "undefined") {
    hidden = "hidden";
    visibilityChange = "visibilitychange";
}
else if (typeof document["msHidden"] !== "undefined") {
    hidden = "msHidden";
    visibilityChange = "msvisibilitychange";
}
else if (typeof document["webkitHidden"] !== "undefined") {
    hidden = "webkitHidden";
    visibilityChange = "webkitvisibilitychange";
}
function handleVisibilityChange() {

    if(window.famobi_ad) return;

    if (document[hidden]) {
        isPageVisible = false;
        if (game)
            game.pauseGame();
    }
    else {
        isPageVisible = true;
        if (game)
            game.unpauseGame();
    }
}
// Warn if the browser doesn't support addEventListener or the Page Visibility API
if (typeof document.addEventListener === "undefined" || typeof document[hidden] === "undefined") {
    console.log("Browser doesn't support the Page Visibility API.");
}
else {
    // Handle page visibility change
    document.addEventListener(visibilityChange, handleVisibilityChange, false);
}
var src;
(function (src) {
    var GameSettings = (function () {
        function GameSettings() {
            this.LEVEL_SPEED = [80, 80, 80, 70, 80, 80, 70, 80, 80, 70, 80, 80, 65, 80, 85, 60, 80, 90, 60, 80, 90, 60, 80, 80, 60, 80, 80, 55, 80, 80, 65, 80, 90, 60, 80, 80, 60, 80, 80, 60, 80, 80, 65, 80, 80, 70, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80, 80];
            this.CHAIN_QUICK_FILL_IN_PERCENTAGE_VALUES = [0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35, 0.35];
            this.FREE_BALL_SPEED = 750;
            this.FREE_BALL_INSERTION_SPEED = 450;
            this.FREE_BALL_INSERTION_SPEED_MULTIPLIER = 6.5;
            this.PATH_ACCELERATION = 10;
            this.PATH_EXPOTENTIAL_ACCELERATION = 1.06;
            this.GAP_COLLAPSING_MAX_SPEED = 700;
            this.GAP_COLLAPSING_ACCELERATION_MULTIPLIER = 1.16;
            this.GAP_COLLAPSING_HIT_SLOWDOWN_FACTOR = 0.75;
            this.GAP_COLLAPSING_STARTING_SPEED = -30;
            this.BALL_EXPLOSION_DELAY = 0;
            this.ZOOMER_COOLDOWN = 400;
            this.ZOOMER_RECOIL = 8;
            this.ZOOMER_RECOIL_DURATION = 100;
            this.ZOOMER_MAX_SAME_COLOR_BALLS_SEQUENCE = 2;
            this.CHAIN_START_SPEED = 650;
            this.CHAIN_LOSE_SPEED = 650;
            this.CHAIN_LOSE_ACCELERATION_MULTIPLIER = 1;
            this.CHAIN_QUICK_FILL_IN_BREAKING_ABSOLUTE_DISTANCE = 150;
            this.SLOWDOWN_POINT_BALLS_COUNT = 15;
            this.SLOWDOWN_POINT_SPEED_MULTIPLIER = 0.5;
            this.SLOWDOWN_POWERUP_SPEED_MULTIPLIER = 0.1;
            this.FIREBALL_SPEED_MULTIPLIER = 0.9;
            this.REWIND_SPEED = -400;
            this.SLOWDOWN_POWERUP_DURATION = 3000;
            this.REWIND_POWERUP_DURATION = 3000;
            this.LASER_POWERUP_DURATION = 7000;
            this.LASER_FREE_BALL_SPEED_MULTIPLIER = 1.75;
            this.LIGHTING_DELAY_BETWEEN_STRIKES = 25;
            this.LIGHTING_MIN_TARGETS = 3;
            this.LIGHTING_MAX_TARGETS = 6;
            this.BOMB_EXPLOSION_RADIUS = 140;
            this.BOMB_EXPLOSION_DELAY = 50;
            this.PATH_SPEED_AFTER_DESTROYING_TAIL = 0.1;
            this.FIREBALL_ANGLE = 18;
            this.PATH_ARROW_STEP = 20;
            this.PATH_ARROW_BASE_DELAY = 150;
            this.PATH_ARROW_DURATION = 1100;
            this.PATH_FINISHED_BONUS_DELAY = 65;
            this.PATH_FINISHED_BONUS_SCORE = 10;
            this.PATH_FINISHED_BONUS_STEP = 60;
            this.SLOWDOWN_APPEARING_CHANCE = 0.1;
            this.REWIND_APPEARING_CHANCE = 0.1;
            this.BOMB_APPEARING_CHANCE = 0.1;
            this.LIGHTING_APPEARING_CHANCE = 0.1;
            this.LASER_APPEARING_CHANCE = 0.1;
            this.FIREBALL_APPEARING_CHANCE = 0.1;
            this.CHANCE_APPEARING_MULTIPLIER = 1.05;
            this.POWERUP_LIFETIME = 20000;
            this.POWERUP_COOLDOWN = 5000;
            this.POWERUP_TIMER = 10000;
            this.POWERUP_TIMER_DEVIATION = 0.15;
            this.MAX_ACTIVE_POWERUPS = 4;
            this.ZOOMER_PRIORITY_DISTANCE = 200;
            this.ZOOMER_PRIORITY_BALLS_LIMIT = 5;
            this.ZOOMER_PRIORITY_PROBABILITY = 0.7;
            this.COIN_CHANCE = 0.6;
            this.COIN_LIFETIME = 20000;
            this.COIN_TIMER = 12000;
            this.COIN_TIMER_DEVIATION = 0.1;
            this.MAX_ACTIVE_COINS = 3;
            this.INSTANTLY_ADD_ALL_COINS = false;
            this.BALL_SCORE = 10;
            this.COIN_SCORE = 100;
            this.TIME_BONUS_POINTS_PER_SECOND_PENALTY = 5;
            this.PATH_GENERATOR_USE_SINGLE_COLOR = false;
        }
        GameSettings.prototype.getBallSpeed = function () {
            return this.LEVEL_SPEED[Settings.CURRENT_LEVEL] ? this.LEVEL_SPEED[Settings.CURRENT_LEVEL] : 80;
        };
        GameSettings.prototype.getChainQuickFillInPercentage = function () {
            return this.CHAIN_QUICK_FILL_IN_PERCENTAGE_VALUES[Settings.CURRENT_LEVEL] ? this.CHAIN_QUICK_FILL_IN_PERCENTAGE_VALUES[Settings.CURRENT_LEVEL] : 0.35;
        };
        return GameSettings;
    }());
    src.GameSettings = GameSettings;
    var Settings = (function () {
        function Settings() {
        }
        //FONTS
        Settings.FONT_FAMILY = 'Germania One';
        Settings.DEFAULT_FONT_FAMILY = 'px ' + Settings.FONT_FAMILY;
        //ATLASES
        Settings.PRELOADER_ATLAS = 'preloader';
        Settings.GAME_ATLAS = 'game';
        Settings.UI_ATLAS = 'ui';
        Settings.FX_ATLAS = 'fx';
        //LEVEL
        Settings.CURRENT_LEVEL = 0;
        Settings.TOTAL_LEVELS = 45;
        Settings.LAST_UNLOCKED_LEVEL = 1;
        //LEVELS MENU
        Settings.LEVELS_WHEEL_AMPLIFIER = 9;
        Settings.LEVELS_WHEEL_EASING_POWER = 5;
        Settings.LEVELS_WHEEL_MIN_SOUND_INTERVAL = 30;
        Settings.LEVELS_ARROW_ANGLE = 0.1;
        //PATH GENERATOR
        Settings.USE_NEW_PATH_GENERATOR = false;
        //PATH BUILDER
        Settings.DEFAULT_TENSION = 0.5;
        Settings.POINTS_PER_SEGMENT = 10;
        Settings.PATTERN_DRAWING_INTERVAL = 5;
        //PATH
        Settings.PATH_SHADOW_DELTA = -1.5;
        Settings.PATH_LIGHT_DELTA = 1.5;
        //BALL
        Settings.BALL_DIAMETER = 45;
        //BALLS CHAIN
        Settings.INSERT_BALL_REACTION_DELAY = 50; //ms
        Settings.GAP_DISAPPEARING_REACTION_DELAY = 75; //ms
        //CANNON
        Settings.ACTIVE_BALL_POSITION = new Phaser.Point(0, -52);
        Settings.NEXT_BALL_POSITION = new Phaser.Point(0, 25.5);
        Settings.NEXT_BALL_SCALE = 0.47;
        Settings.CANNON_TOUCH_ZONE_DIAMETER = 70;
        //PLATFORM
        Settings.PLATFORM_TOUCH_ZONE_DIAMETER = 110;
        Settings.PLATFORM_HIGHLIGHT_CHECKING_PERIOD = 15;
        Settings.PLATFORM_ROTATION_TIME = 8000;
        Settings.PLATFORM_ROTATION_SPEED = 1.6;
        //POWERUPS
        Settings.LIGHTING_STRIKE_COLLAPSE_DELAY = 400;
        //EDITOR
        Settings.EDITOR_PIXELS_PER_CLICK = 1;
        Settings.EDITOR_BALL_SCALE = 0.5;
        Settings.EDITOR_SHOW_BALLS = false;
        //LOCALSTORAGE
        Settings.STORAGE_NAME = 'Totemia_v1.0.4';
        Settings.EDITOR_STORAGE_NAME = 'Zuma_Levels';
        //TEXTS
        Settings.COMBO_TEXT_SPACING = -2;
        Settings.SCORE_TEXT_SPACING = -1;
        //WINDOWS
        Settings.TRANSITION_IN_DURATION = 300;
        Settings.TRANSITION_OUT_DURATION = 250;
        Settings.WINDOW_BACKGROUND_ALPHA = 0.82;
        //SETTINGS
        Settings.RELEASE_VERSION = true;
        Settings.INSTANT_START_FOR_MOBILES = true;
        Settings.MUSIC_ENABLED_BY_DEFAULT = true;
        Settings.REALTIME_CALCULATIONS = true;
        Settings.ENABLE_DEBUG_OUTPUT = false;
        Settings.ENABLE_PRELOADER_OUTPUT = false;
        Settings.UNLOCK_ALL_LEVELS = false;
        Settings.DISPLAY_FPS = false;
        Settings.GAME_VERSION = "v1.03a";
        //GAME PARAMETERS
        Settings.game = new GameSettings();
        return Settings;
    }());
    src.Settings = Settings;
})(src || (src = {}));
var src;
(function (src) {
    var AutoAlignableEffect = (function (_super) {
        __extends(AutoAlignableEffect, _super);
        function AutoAlignableEffect(game, targetScale) {
            var _this = _super.call(this, game, null) || this;
            _this.targetScale = targetScale;
            return _this;
        }
        AutoAlignableEffect.prototype.setInitialPosition = function () {
            var halfWidth = this.width * this.targetScale / 2;
            var halfHeight = this.height * this.targetScale / 2;
            this.x = (this.x > src.CustomScaleManager.ORIGINAL_WIDTH - halfWidth) ? src.CustomScaleManager.ORIGINAL_WIDTH - halfWidth - AutoAlignableEffect.MARGIN : (this.x < halfWidth) ? halfWidth + AutoAlignableEffect.MARGIN : this.x;
            this.y = (this.y > src.CustomScaleManager.ORIGINAL_HEIGHT - halfHeight) ? src.CustomScaleManager.ORIGINAL_HEIGHT - halfHeight - AutoAlignableEffect.MARGIN : (this.y < halfHeight) ? halfHeight + AutoAlignableEffect.MARGIN : this.y;
        };
        AutoAlignableEffect.MARGIN = 5;
        return AutoAlignableEffect;
    }(Phaser.Group));
    src.AutoAlignableEffect = AutoAlignableEffect;
})(src || (src = {}));
///<reference path="AutoAlignableEffect.ts"/>
var src;
(function (src) {
    var Inscription = (function (_super) {
        __extends(Inscription, _super);
        function Inscription(effectsManager, spriteName, x, y, contentScale, delay, appearingDuration, disappearingDuration) {
            if (appearingDuration === void 0) { appearingDuration = 250; }
            if (disappearingDuration === void 0) { disappearingDuration = 900; }
            var _this = _super.call(this, src.App.instance, contentScale) || this;
            _this.effectsManager = effectsManager;
            _this.appearingTweenDuration = appearingDuration;
            _this.disappearingTweenDuration = disappearingDuration;
            _this.spriteName = spriteName;
            _this.position.set(x, y);
            _this.buildContent();
            _this.setInitialPosition();
            _this.animateContent(delay);
            return _this;
        }
        Inscription.prototype.buildContent = function () {
            //combo text
            this.mainSprite = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, this.spriteName));
            this.mainSprite.anchor.setTo(0.5, 0.5);
        };
        Inscription.prototype.animateContent = function (delay) {
            this.scale.set(this.targetScale);
            this.animationA(delay);
        };
        Inscription.prototype.animationA = function (delay) {
            var _this = this;
            //appearing tween
            this.scale.setTo(0);
            this.appearingTween = this.game.add.tween(this.scale)
                .to({
                x: this.targetScale,
                y: this.targetScale
            }, this.appearingTweenDuration, Phaser.Easing.Back.Out, true, delay);
            //disappearing tween
            this.disappearingTween = this.game.add.tween(this)
                .to({ y: this.y - 80, alpha: 0 }, this.disappearingTweenDuration, Phaser.Easing.Cubic.In, true, delay);
            this.disappearingTween.onComplete.add(function () { return _this.destroy(); });
        };
        Inscription.prototype.animationB = function (delay) {
            var _this = this;
            //appearing tween
            this.alpha = 0.3;
            this.visible = false;
            this.appearingTween = this.game.add.tween(this)
                .to({
                alpha: 0.9,
                y: this.y - 80
            }, this.appearingTweenDuration, Phaser.Easing.Back.Out, true, delay);
            this.appearingTween.onStart.add(function () {
                _this.visible = true;
            }, this);
            //tween scale
            this.scale.setTo(0);
            this.game.add.tween(this.scale)
                .to({
                x: this.targetScale,
                y: this.targetScale
            }, this.appearingTweenDuration, Phaser.Easing.Back.Out, true, delay);
            //disappearing tween
            this.disappearingTween = this.game.add.tween(this)
                .to({ alpha: 0.0, y: this.y - 120 }, this.disappearingTweenDuration, Phaser.Easing.Linear.None)
                .delay(200);
            this.disappearingTween.onComplete.add(function () { return _this.destroy(); });
            //chain tweens
            this.appearingTween.chain(this.disappearingTween);
        };
        Inscription.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.effectsManager = null;
            this.mainSprite = null;
            this.appearingTween = null;
            this.disappearingTween = null;
        };
        return Inscription;
    }(src.AutoAlignableEffect));
    src.Inscription = Inscription;
})(src || (src = {}));
///<reference path="Inscription.ts"/>
var src;
(function (src) {
    var CoinBonus = (function (_super) {
        __extends(CoinBonus, _super);
        function CoinBonus(effectsManager, x, y, delay) {
            return _super.call(this, effectsManager, 'coinBonus0000', x, y, 0.75, delay, 250, 350) || this;
        }
        CoinBonus.prototype.animateContent = function (delay) {
            this.animationB(delay);
        };
        return CoinBonus;
    }(src.Inscription));
    src.CoinBonus = CoinBonus;
})(src || (src = {}));
///<reference path="AutoAlignableEffect.ts"/>
var src;
(function (src) {
    var ComboEffect = (function (_super) {
        __extends(ComboEffect, _super);
        function ComboEffect(effectsManager, x, y, comboMultiplier, delay, soundIndex) {
            var _this = _super.call(this, src.App.instance, 0.9 + 0.08 * comboMultiplier) || this;
            _this.effectsManager = effectsManager;
            _this.comboMultiplier = comboMultiplier;
            _this.soundIndex = Phaser.Math.clamp(soundIndex != 0 ? soundIndex : comboMultiplier, 1, 10);
            _this.position.set(x, y);
            _this.buildContent();
            _this.setInitialPosition();
            _this.animateContentC(delay);
            return _this;
        }
        ComboEffect.prototype.buildContent = function () {
            //combo text
            this.comboText = this.add(this.game.make.sprite(0, -5, src.Settings.GAME_ATLAS, 'combo' + '0000'));
            this.comboText.anchor.setTo(0.5, 1);
            this.comboText.scale.setTo(0.7);
            //multiplier text
            this.multiplierText = this.add(src.BitmapTextFactory.getComboText(this.comboMultiplier));
            this.multiplierText.position.set(0, 22);
            this.multiplierText.angle = -5;
            this.multiplierText.scale.setTo(1);
        };
        ComboEffect.prototype.animateContentC = function (delay) {
            var _this = this;
            //appearing tween
            this.scale.setTo(0);
            this.appearingTween = this.game.add.tween(this.scale)
                .to({
                x: this.targetScale,
                y: this.targetScale
            }, 250, Phaser.Easing.Back.Out, true, delay);
            this.game.sound.play('combo' + this.soundIndex, Phaser.Math.clamp(0.15 + this.comboMultiplier * 0.1, 0.3, 0.75));
            //effects
            var multiplierTextRotationTween = src.App.instance.add.tween(this.multiplierText)
                .to({ angle: 5 }, 250, Phaser.Easing.Linear.None, true, 0, 2);
            var multiplierTextScaleTween = src.App.instance.add.tween(this.multiplierText.scale)
                .to({ x: 1.07, y: 1.07 }, 250, Phaser.Easing.Linear.None, true, 0, 2);
            multiplierTextRotationTween.yoyo(true, 0);
            multiplierTextScaleTween.yoyo(true, 0);
            //disappearing tween
            this.disappearingTween = this.game.add.tween(this)
                .to({ y: this.y - 50, alpha: 0 }, 800, Phaser.Easing.Linear.None, false, 0);
            this.disappearingTween.onComplete.add(function () { return _this.destroy(); });
            //chain tweens
            this.appearingTween.chain(this.disappearingTween);
        };
        ComboEffect.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.effectsManager = null;
            this.comboText = null;
            this.multiplierText = null;
            this.appearingTween = null;
            this.disappearingTween = null;
        };
        return ComboEffect;
    }(src.AutoAlignableEffect));
    src.ComboEffect = ComboEffect;
})(src || (src = {}));
var src;
(function (src) {
    var GapBonus = (function (_super) {
        __extends(GapBonus, _super);
        function GapBonus(effectsManager, gapMultiplier, x, y, delay) {
            var _this = this;
            var spriteIndex = gapMultiplier < 1 ? 1 : (gapMultiplier > GapBonus.GAP_BONUS_SPRITES) ? GapBonus.GAP_BONUS_SPRITES : gapMultiplier;
            _this = _super.call(this, effectsManager, 'gapBonus' + spriteIndex + '0000', x, y, GapBonus.getSpriteScale(spriteIndex), delay) || this;
            _this.gapMultiplier = gapMultiplier;
            _this.game.time.events.add(delay, function () { return _this.game.sound.play('gap_bonus', 0.5); });
            return _this;
        }
        GapBonus.getSpriteScale = function (gapMultiplier) {
            var result = 1;
            switch (gapMultiplier) {
                case 1:
                    result = 0.75;
                    break;
                case 2:
                    result = 0.7;
                    break;
                case 3:
                    result = 0.85;
                    break;
                case 4:
                    result = 1;
                    break;
            }
            return result;
        };
        GapBonus.GAP_BONUS_SPRITES = 4;
        return GapBonus;
    }(src.Inscription));
    src.GapBonus = GapBonus;
})(src || (src = {}));
var src;
(function (src) {
    var ScoresEffect = (function (_super) {
        __extends(ScoresEffect, _super);
        function ScoresEffect(effectsManager, color, x, y, scores, delay, targetScale) {
            var _this = _super.call(this, src.App.instance, targetScale) || this;
            _this.effectsManager = effectsManager;
            _this.color = color;
            _this.scores = scores;
            _this.position.set(x, y);
            _this.buildContent();
            _this.setInitialPosition();
            _this.animateContentA(delay);
            return _this;
        }
        ScoresEffect.prototype.buildContent = function () {
            //scores text
            this.scoresText = this.add(src.BitmapTextFactory.getScoreText(this.scores, this.color));
            this.scoresText.position.set(0, 0);
            var targetScale = 0.9;
            var halfWidth = this.width * targetScale / 2;
            var halfHeight = this.height * targetScale / 2;
            this.x = (this.x > src.CustomScaleManager.ORIGINAL_WIDTH - halfWidth) ? src.CustomScaleManager.ORIGINAL_WIDTH - halfWidth - 5 : (this.x < halfWidth) ? halfWidth + 5 : this.x;
            this.y = (this.y > src.CustomScaleManager.ORIGINAL_HEIGHT - halfHeight + 30) ? src.CustomScaleManager.ORIGINAL_HEIGHT - halfHeight + 30 : (this.y < halfHeight) ? halfHeight + 5 : this.y;
        };
        ScoresEffect.prototype.animateContentA = function (delay) {
            var _this = this;
            //appearing tween
            this.scale.set(0.01);
            this.game.add.tween(this.scale)
                .to({
                x: this.targetScale,
                y: this.targetScale
            }, 300, Phaser.Easing.Back.Out, true, delay);
            //tween appearing position
            this.appearingTween = this.game.add.tween(this)
                .to({ y: this.y - 40 }, 300, Phaser.Easing.Back.Out, true, delay);
            this.appearingTween.onStart.add(function () { return src.ScoreManager.instance.addScores(_this.scores); });
            //disappearing tween
            this.disappearingTween = this.game.add.tween(this)
                .to({ alpha: 0.0, y: this.y - 100 }, 750, Phaser.Easing.Cubic.In, false);
            this.disappearingTween.onComplete.add(function () { return _this.destroy(); });
            //chain tweens
            this.appearingTween.chain(this.disappearingTween);
        };
        ScoresEffect.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.effectsManager = null;
            this.scoresText = null;
            this.appearingTween = null;
            this.disappearingTween = null;
        };
        return ScoresEffect;
    }(src.AutoAlignableEffect));
    src.ScoresEffect = ScoresEffect;
})(src || (src = {}));
var src;
(function (src) {
    var LaserEffect = (function (_super) {
        __extends(LaserEffect, _super);
        function LaserEffect() {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.buildSprites();
            return _this;
        }
        LaserEffect.prototype.buildSprites = function () {
            this.laserRays = [];
            for (var i = 0; i < LaserEffect.TOTAL_PARTS; i++) {
                var laserRay = this.add(this.game.make.sprite(0, -i * LaserEffect.LASER_PART_LENGTH, src.Settings.GAME_ATLAS, 'laserRay0000'));
                laserRay.anchor.set(0.5, 1);
                laserRay.animations.add('rayAnimation', Phaser.Animation.generateFrameNames('laserRay', 0, 13, '', 4).reverse()).play(60, true);
                this.laserRays.push(laserRay);
            }
        };
        LaserEffect.prototype.setLength = function (length) {
            var parts = length > 0 ? Math.floor(length / LaserEffect.LASER_PART_LENGTH) : LaserEffect.TOTAL_PARTS;
            parts = parts < 1 ? 1 : parts;
            for (var i = 0; i < this.laserRays.length; i++) {
                this.laserRays[i].visible = (i < parts);
            }
            this.scale.set(1, length > 0 ? length / (parts * LaserEffect.LASER_PART_LENGTH) : 1);
        };
        LaserEffect.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.laserRays = null;
        };
        LaserEffect.TOTAL_PARTS = 12;
        LaserEffect.LASER_PART_LENGTH = 75;
        return LaserEffect;
    }(Phaser.Group));
    src.LaserEffect = LaserEffect;
})(src || (src = {}));
var src;
(function (src) {
    var Lighting = (function (_super) {
        __extends(Lighting, _super);
        function Lighting(initialBall, targetBall) {
            var _this = _super.call(this, src.App.instance, targetBall.x, targetBall.y, src.Settings.GAME_ATLAS, 'lighting0000') || this;
            _this.anchor.set(0.5, 0);
            _this.initialBallPosition = initialBall.position.clone();
            _this.targetBallPosition = targetBall.position.clone();
            _this.targetBall = targetBall;
            _this.update();
            _this.blinkAnimation = _this.animations.add('blinkAnimation', Phaser.Animation.generateFrameNames('lighting', 0, Lighting.LIGHTING_FRAMES - 1, '', 4));
            _this.endAnimation = _this.animations.add('endAnimation', Phaser.Animation.generateFrameNames('lightingEnd', 0, Lighting.DISAPPEARING_FRAMES - 1, '', 4));
            return _this;
        }
        Lighting.prototype.setDelay = function (delay) {
            var _this = this;
            this.visible = false;
            this.game.time.events.add(delay, function () {
                if (_this.targetBall && _this.targetBall.isAlive && !_this.targetBall.isUnderground) {
                    _this.startAnimations();
                }
                else {
                    _this.destroy();
                }
            });
            return this;
        };
        Lighting.prototype.startAnimations = function () {
            var _this = this;
            this.game.sound.play('lighting', 0.5);
            this.visible = true;
            this.blinkAnimation.play(Lighting.FPS, false, false);
            this.blinkAnimation.onComplete.add(function () {
                _this.endAnimation.play(Lighting.FPS, false, false);
                _this.endAnimation.onComplete.add(function () {
                    _this.destroy();
                });
                _this.scale.set(1, 1);
                if (_this.targetBall && _this.targetBall.isAlive && !_this.targetBall.isUnderground) {
                    src.ScoreManager.instance.displayScores(src.ScoreManager.instance.calculateScores(1), true, _this.targetBall.color, _this.targetBall.x, _this.targetBall.y);
                    _this.targetBall.explodeBall();
                }
            });
        };
        Lighting.prototype.update = function () {
            _super.prototype.update.call(this);
            if (this.targetBall.isAlive) {
                this.targetBallPosition.copyFrom(this.targetBall.position);
                this.scale.set(1, Phaser.Math.distance(this.targetBallPosition.x, this.targetBallPosition.y, this.initialBallPosition.x, this.initialBallPosition.y) / 130);
            }
            else if (Phaser.Math.distance(this.targetBallPosition.x, this.targetBallPosition.y, this.initialBallPosition.x, this.initialBallPosition.y) < 120) {
                this.scale.set(1, Phaser.Math.distance(this.targetBallPosition.x, this.targetBallPosition.y, this.initialBallPosition.x, this.initialBallPosition.y) / 130);
            }
            this.position.copyFrom(this.targetBallPosition);
            this.rotation = Phaser.Math.angleBetween(this.targetBallPosition.x, this.targetBallPosition.y, this.initialBallPosition.x, this.initialBallPosition.y) - Math.PI / 2;
        };
        Lighting.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.blinkAnimation = null;
            this.endAnimation = null;
        };
        Lighting.LIGHTING_FRAMES = 15;
        Lighting.DISAPPEARING_FRAMES = 13;
        Lighting.TOTAL_FRAMES = Lighting.LIGHTING_FRAMES + Lighting.DISAPPEARING_FRAMES;
        Lighting.FPS = 180;
        return Lighting;
    }(Phaser.Sprite));
    src.Lighting = Lighting;
})(src || (src = {}));
var src;
(function (src) {
    var PathArrow = (function (_super) {
        __extends(PathArrow, _super);
        function PathArrow(x, y, rotation, delay) {
            var _this = _super.call(this, src.App.instance, x, y, src.Settings.GAME_ATLAS, 'pathArrow0000') || this;
            _this.anchor.set(0.5);
            _this.rotation = rotation;
            _this.animations.add('arrowAnimation', Phaser.Animation.generateFrameNames('pathArrow', 0, 20, '', 4));
            _this.game.time.events.add(delay, function () { _this.animations.play('arrowAnimation', 60, false, true); });
            return _this;
        }
        return PathArrow;
    }(Phaser.Sprite));
    src.PathArrow = PathArrow;
})(src || (src = {}));
var src;
(function (src) {
    var FreezeEffect = (function (_super) {
        __extends(FreezeEffect, _super);
        function FreezeEffect(slowdownPowerup) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.slowdownPowerup = slowdownPowerup;
            _this.buildSprites();
            return _this;
        }
        FreezeEffect.prototype.buildSprites = function () {
            this.topLeft = this.add(new src.FrozenScreenQuarter(20.5, 96, 0, 0, 1, 1));
            this.topRight = this.add(new src.FrozenScreenQuarter(src.CustomScaleManager.ORIGINAL_WIDTH - 20, 96, 0, 0, -1, 1));
            this.downLeft = this.add(new src.FrozenScreenQuarter(20.5, src.CustomScaleManager.ORIGINAL_HEIGHT - 19, 0, 0, 1, -1));
            this.downRight = this.add(new src.FrozenScreenQuarter(src.CustomScaleManager.ORIGINAL_WIDTH - 20, src.CustomScaleManager.ORIGINAL_HEIGHT - 19, 0, 0, -1, -1));
        };
        FreezeEffect.prototype.freeze = function () {
            this.topLeft.freeze();
            this.topRight.freeze();
            this.downLeft.freeze();
            this.downRight.freeze();
            this.game.sound.play('freezing', 0.7);
            this.game.tweens.removeFrom(this.slowdownPowerup);
            this.game.add.tween(this.slowdownPowerup)
                .to({ slowdownMultiplier: src.Settings.game.SLOWDOWN_POWERUP_SPEED_MULTIPLIER }, 1000 * src.FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_COUNT / src.FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_FRAMERATE, Phaser.Easing.Linear.None, true);
        };
        FreezeEffect.prototype.onFrozen = function () {
            this.slowdownPowerup.onFrozen();
        };
        FreezeEffect.prototype.onMelted = function () {
            this.slowdownPowerup.onMelted();
        };
        FreezeEffect.prototype.melt = function () {
            this.topLeft.melt();
            this.topRight.melt();
            this.downLeft.melt();
            this.downRight.melt();
            this.game.sound.play('unfreezing', 0.7);
            this.game.tweens.removeFrom(this.slowdownPowerup);
            this.game.add.tween(this.slowdownPowerup)
                .to({ slowdownMultiplier: 1 }, 1000 * src.FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_COUNT / src.FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_FRAMERATE, Phaser.Easing.Linear.None, true);
        };
        FreezeEffect.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.slowdownPowerup = null;
            this.topLeft = null;
            this.downLeft = null;
            this.topRight = null;
            this.downRight = null;
        };
        return FreezeEffect;
    }(Phaser.Group));
    src.FreezeEffect = FreezeEffect;
})(src || (src = {}));
var src;
(function (src) {
    var FrozenScreenQuarter = (function (_super) {
        __extends(FrozenScreenQuarter, _super);
        function FrozenScreenQuarter(x, y, anchorX, anchorY, scaleX, scaleY) {
            var _this = _super.call(this, src.App.instance, x, y, src.Settings.GAME_ATLAS, 'frozenGlass0000') || this;
            _this.anchor.set(anchorX, anchorY);
            _this.scale.set(2 * scaleX, 2 * scaleY);
            _this.appearingAnimation = _this.animations.add('appearingAnimation', Phaser.Animation.generateFrameNames('frozenGlass', 0, FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_COUNT, '', 4));
            _this.appearingAnimation.onComplete.add(function () {
                if (_this.parent && _this.parent instanceof src.FreezeEffect) {
                    _this.parent.onFrozen();
                }
            });
            _this.disappearingAnimation = _this.animations.add('disappearingAnimation', Phaser.Animation.generateFrameNames('frozenGlass', 0, FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_COUNT, '', 4).reverse());
            _this.disappearingAnimation.onComplete.add(function () {
                if (_this.parent && _this.parent instanceof src.FreezeEffect) {
                    _this.parent.onMelted();
                }
            });
            return _this;
        }
        FrozenScreenQuarter.prototype.freeze = function () {
            this.appearingAnimation.play(FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_FRAMERATE, false, false);
        };
        FrozenScreenQuarter.prototype.melt = function () {
            this.disappearingAnimation.play(FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_FRAMERATE, false, false);
        };
        FrozenScreenQuarter.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.appearingAnimation = null;
            this.disappearingAnimation = null;
        };
        FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_COUNT = 29;
        FrozenScreenQuarter.FREEZE_ANIMATION_FRAMES_FRAMERATE = 30;
        return FrozenScreenQuarter;
    }(Phaser.Sprite));
    src.FrozenScreenQuarter = FrozenScreenQuarter;
})(src || (src = {}));
var src;
(function (src) {
    var FeathersAnimation = (function (_super) {
        __extends(FeathersAnimation, _super);
        function FeathersAnimation(x, y) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.position.set(x, y);
            _this.buildLeafs();
            return _this;
        }
        FeathersAnimation.prototype.buildLeafs = function () {
            this.leafLeftA = this.constructLeaf(-28, -140, -12, 1, 1);
            this.leafLeftB = this.constructLeaf(-28, -142, -59, 1, 1);
            this.leafLeftC = this.constructLeaf(-28, -145, -117, 1, 1);
            this.leafRightA = this.constructLeaf(28, -140, 12, 1, -1);
            this.leafRightB = this.constructLeaf(28, -142, 59, 1, -1);
            this.leafRightC = this.constructLeaf(28, -145, 117, 1, -1);
        };
        FeathersAnimation.prototype.startTweens = function () {
            this.tweenFeatherJumping(this.leafLeftA, -42, -12);
            this.tweenFeatherJumping(this.leafLeftB, -99, -59);
            this.tweenFeatherJumping(this.leafLeftC, -157, -107);
            this.tweenFeatherJumping(this.leafRightA, 42, 12);
            this.tweenFeatherJumping(this.leafRightB, 99, 59);
            this.tweenFeatherJumping(this.leafRightC, 157, 107);
        };
        FeathersAnimation.prototype.constructLeaf = function (x, y, angle, scale, scaleXMultiplier) {
            var leaf = this.add(this.game.make.sprite(x, y, src.Settings.UI_ATLAS, 'feather' + '0000'));
            leaf.anchor.set(0.5, 1);
            leaf.angle = angle;
            leaf.scale.set(scale);
            leaf.scale.x *= scaleXMultiplier;
            return leaf;
        };
        FeathersAnimation.prototype.tweenFeatherJumping = function (leaf, startAngle, endAngle) {
            this.game.tweens.removeFrom(leaf);
            leaf.angle = startAngle;
            var secondTween = this.game.add.tween(leaf)
                .to({ angle: endAngle + (endAngle - startAngle) / 1.6 }, 400, Phaser.Easing.Sinusoidal.InOut, true, 200);
            var thirdTween = this.game.add.tween(leaf)
                .to({ angle: endAngle }, 200, Phaser.Easing.Linear.None, false, 0);
            secondTween.chain(thirdTween);
        };
        return FeathersAnimation;
    }(Phaser.Group));
    src.FeathersAnimation = FeathersAnimation;
})(src || (src = {}));
var src;
(function (src) {
    var LeafsAnimation = (function (_super) {
        __extends(LeafsAnimation, _super);
        function LeafsAnimation(x, y) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.position.set(x, y);
            _this.buildLeafs();
            return _this;
        }
        LeafsAnimation.prototype.buildLeafs = function () {
            this.leafLeftA = this.constructLeaf(-35, 25, -24, 1, 1);
            this.leafLeftC = this.constructLeaf(-73, 4, -87, 0.64, 1);
            this.leafLeftB = this.constructLeaf(-60, 15, -48, 0.82, 1);
            this.leafRightA = this.constructLeaf(35, 25, 24, 1, -1);
            this.leafRightC = this.constructLeaf(73, 4, 87, 0.64, -1);
            this.leafRightB = this.constructLeaf(60, 15, 48, 0.82, -1);
        };
        LeafsAnimation.prototype.startTweens = function () {
            this.tweenLeafJumping(this.leafLeftA, -44, -24, 4);
            this.tweenLeafJumping(this.leafLeftB, -62, -48, -4);
            this.tweenLeafJumping(this.leafLeftC, -97, -87, 6);
            this.tweenLeafJumping(this.leafRightA, 44, 24, -4);
            this.tweenLeafJumping(this.leafRightB, 62, 48, 4);
            this.tweenLeafJumping(this.leafRightC, 97, 87, 6);
        };
        LeafsAnimation.prototype.constructLeaf = function (x, y, angle, scale, scaleXMultiplier) {
            var leaf = this.add(this.game.make.sprite(x, y, src.Settings.UI_ATLAS, 'palmLeaf' + '0000'));
            leaf.anchor.set(0.5, 1);
            leaf.angle = angle;
            leaf.scale.set(scale);
            leaf.scale.x *= scaleXMultiplier;
            return leaf;
        };
        LeafsAnimation.prototype.tweenLeafJumping = function (leaf, startAngle, endAngle, deltaAngle) {
            var _this = this;
            this.game.tweens.removeFrom(leaf);
            leaf.angle = startAngle;
            var secondTween = this.game.add.tween(leaf)
                .to({ angle: endAngle + (endAngle - startAngle) / 2 }, 350, Phaser.Easing.Sinusoidal.InOut, true, 150);
            var thirdTween = this.game.add.tween(leaf)
                .to({ angle: endAngle }, 250, Phaser.Easing.Linear.None, false, 0);
            secondTween.chain(thirdTween);
            thirdTween.onComplete.add(function (leaf) { return _this.tweenLeafShaking(leaf, endAngle, deltaAngle); }, this, 0, leaf);
        };
        LeafsAnimation.prototype.tweenLeafShaking = function (leaf, startAngle, deltaAngle) {
            this.game.tweens.removeFrom(leaf);
            var secondTween = this.game.add.tween(leaf)
                .to({ angle: startAngle + deltaAngle }, 1200, Phaser.Easing.Linear.None, true, Math.random() * 400);
            var thirdTween = this.game.add.tween(leaf)
                .to({ angle: startAngle }, 1200, Phaser.Easing.Linear.None, false, 0);
            secondTween.chain(thirdTween);
            thirdTween.chain(secondTween);
        };
        return LeafsAnimation;
    }(Phaser.Group));
    src.LeafsAnimation = LeafsAnimation;
})(src || (src = {}));
var src;
(function (src) {
    var LevelIndicator = (function (_super) {
        __extends(LevelIndicator, _super);
        function LevelIndicator(levelNumber, locked) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.levelNumber = 0;
            _this.isLocked = false;
            _this.levelNumber = levelNumber;
            _this.digit = _this.add(src.BitmapTextFactory.getLevelText(levelNumber > src.Settings.TOTAL_LEVELS ? levelNumber - src.Settings.TOTAL_LEVELS : levelNumber, src.BallColor.GREEN));
            _this.digit.scale.set(1.1);
            _this.lock = _this.add(_this.game.make.group(null));
            var lockSprite = _this.lock.add(_this.game.make.sprite(0, 0, src.Settings.UI_ATLAS, 'lockIcon0000'));
            lockSprite.anchor.set(0.5);
            var lockedNumber = _this.lock.add(src.BitmapTextFactory.getLevelText(levelNumber, src.BallColor.RED));
            lockedNumber.scale.set(0.8);
            lockedNumber.position.set(-2, 22);
            _this.setLocked(locked);
            return _this;
        }
        LevelIndicator.prototype.setLocked = function (value) {
            this.isLocked = value;
            if (this.isLocked) {
                this.digit.visible = false;
                this.lock.visible = true;
            }
            else {
                this.digit.visible = true;
                this.lock.visible = false;
            }
        };
        return LevelIndicator;
    }(Phaser.Group));
    src.LevelIndicator = LevelIndicator;
})(src || (src = {}));
var src;
(function (src) {
    var ResultsBoard = (function (_super) {
        __extends(ResultsBoard, _super);
        function ResultsBoard() {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.buildBoard();
            _this.buildTexts();
            _this.buildSounds();
            return _this;
        }
        /**
         * PUBLIC MEMBERS
         */
        ResultsBoard.prototype.show = function (callback, buttons) {

            window.famobi_analytics.trackScreen(window.famobi_analytics.SCREEN_LEVELRESULT);

            this.callback = callback;
            this.buttons = buttons;

            for(var i = 0; this.buttons && i < this.buttons.length; i++) {
                this.buttons[i].visible = false;
            }

            this.countingSound.volume = 0.8;
            this.addListeners();
            var achievedBestScore = this.updateData();
            this.updateTexts(achievedBestScore);
            if (this.game.state.getCurrentState() instanceof src.Level) {
                this.game.state.getCurrentState().uiManager.scoresValue.text = '' + src.StatsManager.instance.calculateReward();
            }
        };
        ResultsBoard.prototype.hide = function () {
            if (this.countingSound.isPlaying) {
                this.countingSound.stop();
            }
            this.countingSound.volume = 0;
            this.removeListeners();
        };
        /**
         * PRIVATE MEMBERS
         */
        ResultsBoard.prototype.buildTexts = function () {
            _a = this.assignTripleText(0, 'iconBalls0000', 'x99', '99999'), this.balls = _a[0], this.ballsCount = _a[1], this.ballsValue = _a[2];
            _b = this.assignTripleText(1, 'iconCombos0000', 'x99', '99999'), this.combos = _b[0], this.combosCount = _b[1], this.combosValue = _b[2];
            _c = this.assignTripleText(2, 'iconGaps0000', 'x99', '99999'), this.gaps = _c[0], this.gapsCount = _c[1], this.gapsValue = _c[2];
            _d = this.assignTripleText(3, 'iconTime0000', 'x99', '99999'), this.time = _d[0], this.timeCount = _d[1], this.timeValue = _d[2];
            _e = this.assignTripleText(4, 'iconBonus0000', '-', '99999'), this.bonus = _e[0], this.bonusCount = _e[1], this.bonusValue = _e[2];
            _f = this.assignDoubleText(6, 'iconBestScore0000', '', '#87FF12'), this.levelScores = _f[0], this.levelScoresValue = _f[1];
            _g = this.assignDoubleText(7, 'iconScore0000', '', '#FFDB33'), this.levelBest = _g[0], this.levelBestValue = _g[1];
            _h = this.assignDoubleText(8, 'iconTotalScore0000', '', '#F37CE4'), this.totalScores = _h[0], this.totalScoresValue = _h[1];
            var _a, _b, _c, _d, _e, _f, _g, _h;
        };
        ResultsBoard.prototype.buildSounds = function () {
            this.countingSound = this.game.add.sound('scores_counting', 0.8, true);
        };
        ResultsBoard.prototype.buildBoard = function () {
            this.boardSprite = this.add(this.game.make.sprite(0, 0, src.Settings.UI_ATLAS, 'resultsBoard' + '0000'));
            this.boardSprite.anchor.set(0.5);
            this.boardSprite.inputEnabled = true;
            this.levelPlate = this.add(this.game.make.sprite(1, -151, src.Settings.UI_ATLAS, 'levelPlate' + '0000'));
            this.levelPlate.anchor.set(0.5);
            this.levelIconLeft = this.add(this.game.make.sprite(3 - (src.Settings.CURRENT_LEVEL > 9 ? 20 : 15), -151, src.Settings.GAME_ATLAS, 'levelIcon0000'));
            this.levelIconLeft.anchor.set(1, 0.5);
            this.levelIconRight = this.add(this.game.make.sprite(3 + (src.Settings.CURRENT_LEVEL > 9 ? 20 : 15), -151, src.Settings.GAME_ATLAS, 'levelIcon0000'));
            this.levelIconRight.scale.set(-1, 1);
            this.levelIconRight.anchor.set(1, 0.5);
            this.levelText = this.add(src.TextUtils.getShadowText('' + src.Settings.CURRENT_LEVEL, 3, -149, 22, '#FFFFFF', '#2E2E2E', 0, 3, 0.5));
        };
        ResultsBoard.prototype.addListeners = function () {
            this.boardSprite.events.onInputDown.add(function() {
                this.skipCountingAnimations();
            }, this);
        };
        ResultsBoard.prototype.removeListeners = function () {
            this.boardSprite.events.onInputDown.removeAll();
        };
        ResultsBoard.prototype.updateData = function () {
            this.dataHolder = {
                balls: 0,
                combos: 0,
                gaps: 0,
                time: 0,
                bonus: 0,
                levelScore: src.StatsManager.instance.calculateReward(),
                levelBest: src.ScoreManager.instance.getLevelScores(src.Settings.CURRENT_LEVEL),
                totalScore: src.ScoreManager.instance.getTotalScores()
            };
            if (src.PlayerStatisticsCollector.instance.time[src.Settings.CURRENT_LEVEL] > 0) {
                src.PlayerStatisticsCollector.instance.time[src.Settings.CURRENT_LEVEL] = Math.min(src.PlayerStatisticsCollector.instance.time[src.Settings.CURRENT_LEVEL], src.StatsManager.instance.time);
            }
            else {
                src.PlayerStatisticsCollector.instance.time[src.Settings.CURRENT_LEVEL] = src.StatsManager.instance.time;
            }
            src.PlayerStatisticsCollector.instance.balls[src.Settings.CURRENT_LEVEL] = src.StatsManager.instance.balls;
            src.PlayerStatisticsCollector.instance.gaps[src.Settings.CURRENT_LEVEL] = src.StatsManager.instance.gaps;
            src.PlayerStatisticsCollector.instance.combos[src.Settings.CURRENT_LEVEL] = src.StatsManager.instance.combos;
            src.PlayerStatisticsCollector.instance.coins[src.Settings.CURRENT_LEVEL] = src.StatsManager.instance.coins;
            if (this.game.state.getCurrentState() instanceof src.Level) {
                var distances = "[";
                for (var _i = 0, _a = this.game.state.getCurrentState().pathManager.paths; _i < _a.length; _i++) {
                    var path = _a[_i];
                    distances += path.pathFinalizer.bonusPoints + ' ';
                }
                src.PlayerStatisticsCollector.instance.distanceToIdol[src.Settings.CURRENT_LEVEL] = distances + "]";
            }
            this.levelText.setText('' + src.Settings.CURRENT_LEVEL);
            src.Settings.LAST_UNLOCKED_LEVEL = Math.max(src.Settings.LAST_UNLOCKED_LEVEL, (src.Settings.CURRENT_LEVEL < src.Settings.TOTAL_LEVELS) ? src.Settings.CURRENT_LEVEL + 1 : src.Settings.TOTAL_LEVELS);
            var achievedBestScore = src.ScoreManager.instance.updateLevelScores(src.Settings.CURRENT_LEVEL, src.StatsManager.instance.calculateReward());
            src.LocalStorageController.instance.save();
            return achievedBestScore;
        };
        ResultsBoard.prototype.updateTexts = function (runCallback) {
            var _this = this;
            if (!(this.game.state.getCurrentState() instanceof src.Level)) {
                return;
            }
            this.levelIconLeft.x = 3 - (src.Settings.CURRENT_LEVEL > 9 ? 16 : 10);
            this.levelIconRight.x = 3 + (src.Settings.CURRENT_LEVEL > 9 ? 16 : 10);
            this.fadeIn(this.balls, 150, 700);
            this.fadeIn(this.combos, 150, 800);
            this.fadeIn(this.gaps, 150, 900);
            this.fadeIn(this.time, 150, 1000);
            this.fadeIn(this.bonus, 150, 1100);
            this.fadeIn(this.levelScores, 150, 1200);
            this.fadeIn(this.levelBest, 150, 1300);
            this.fadeIn(this.totalScores, 150, 1400);
            this.fadeIn(this.ballsCount, 150, 700, 'x' + src.StatsManager.instance.balls);
            this.fadeIn(this.combosCount, 150, 800, src.StatsManager.instance.combos > 0 ? 'x' + src.StatsManager.instance.combos : '-');
            this.fadeIn(this.gapsCount, 150, 900, src.StatsManager.instance.gaps > 0 ? 'x' + src.StatsManager.instance.gaps : '-');
            this.fadeIn(this.timeCount, 150, 1000, src.TextUtils.convertMSToHumanTime(src.StatsManager.instance.time));
            this.fadeIn(this.bonusCount, 150, 1100, src.StatsManager.instance.bonus > 0 ? 'x' + src.StatsManager.instance.bonus : '-');
            var delay = 1500;
            var startDelay = delay;
            delay = this.animateText(this.ballsValue, this.dataHolder, "balls", 0, src.StatsManager.instance.ballsScore, delay);
            delay = this.animateText(this.combosValue, this.dataHolder, "combos", 0, src.StatsManager.instance.combosScore, delay);
            delay = this.animateText(this.gapsValue, this.dataHolder, "gaps", 0, src.StatsManager.instance.gapsScore, delay);
            delay = this.animateText(this.timeValue, this.dataHolder, "time", 0, src.StatsManager.instance.timeScore, delay);
            delay = this.animateText(this.bonusValue, this.dataHolder, "bonus", 0, src.StatsManager.instance.bonusScore, delay);
            var endDelay = delay;
            if (endDelay > startDelay) {
                this.soundStartEvent = this.game.time.events.add(startDelay, function () { return _this.countingSound.play(); });
                this.soundEndEvent = this.game.time.events.add(endDelay, function () { return _this.countingSound.stop(); });
            }
            this.fadeIn(this.levelScoresValue, 250, delay + 300, '' + src.StatsManager.instance.calculateReward());
            this.fadeIn(this.levelBestValue, 250, delay + 600, '' + src.ScoreManager.instance.getLevelScores(src.Settings.CURRENT_LEVEL));

            this.fadeIn(this.totalScoresValue, 250, delay + 900, "" + src.ScoreManager.instance.getTotalScores(), function() {
                    this.updateTextsAction();
                }.bind(this));
            if (runCallback && this.callback) {
                this.callbackEvent = this.game.time.events.add(delay + 300, function () { return _this.invokeAndResetCallback(); });
            }
        };
        ResultsBoard.prototype.skipCountingAnimations = function () {
            var _this = this;
            [this.balls, this.ballsCount, this.ballsValue,
                this.combos, this.combosCount, this.combosValue,
                this.gaps, this.gapsCount, this.gapsValue,
                this.time, this.timeCount, this.timeValue,
                this.bonus, this.bonusCount, this.bonusValue,
                this.levelScores, this.levelScoresValue,
                this.levelBest, this.levelBestValue,
                this.totalScores, this.totalScoresValue].forEach(function (textField) {
                _this.game.tweens.removeFrom(textField);
                textField.alpha = 1;
            });

            this.game.tweens.removeFrom(this.dataHolder);
            this.countingSound.stop();
            this.game.time.events.remove(this.soundStartEvent);
            this.game.time.events.remove(this.soundEndEvent);
            this.game.time.events.remove(this.callbackEvent);
            this.dataHolder["balls"] = src.StatsManager.instance.ballsScore;
            this.dataHolder["combos"] = src.StatsManager.instance.combosScore;
            this.dataHolder["gaps"] = src.StatsManager.instance.gapsScore;
            this.dataHolder["time"] = src.StatsManager.instance.timeScore;
            this.dataHolder["bonus"] = src.StatsManager.instance.bonusScore;
            this.ballsValue.setText('' + ~~this.dataHolder["balls"]);
            this.combosValue.setText('' + ~~this.dataHolder["combos"]);
            this.gapsValue.setText('' + ~~this.dataHolder["gaps"]);
            this.timeValue.setText('' + ~~this.dataHolder["time"]);
            this.bonusValue.setText('' + ~~this.dataHolder["bonus"]);

            this.updateTextsAction();

            this.invokeAndResetCallback();
        };
        ResultsBoard.prototype.updateTextsAction = function () {

            setTimeout(function() {
                Promise.all([
                    window.famobi_analytics.trackEvent("EVENT_LEVELSUCCESS", {
                        levelName: ""+src.Settings.CURRENT_LEVEL
                    }),
                    window.famobi_analytics.trackEvent("EVENT_LEVELSCORE", {
                        levelName: ""+src.Settings.CURRENT_LEVEL,
                        levelScore: src.StatsManager.instance.calculateReward()
                    }),
                    window.famobi_analytics.trackEvent("EVENT_TOTALSCORE", {
                        totalScore: src.ScoreManager.instance.getTotalScores()
                    })
                ]).then(function() {
                    for(var i = 0; this.buttons && i < this.buttons.length; i++) {
                        this.buttons[i].visible = true;
                    }
                }.bind(this), function() {
                    for(var i = 0; this.buttons && i < this.buttons.length; i++) {
                        this.buttons[i].visible = true;
                    }
                }.bind(this));
            }.bind(this), 500);
        };

        ResultsBoard.prototype.invokeAndResetCallback = function () {

            this.removeListeners();
            if (this.callback) {
                this.callback();
            }
            this.callback = null;
        };
        /**
         *  HELPERS
         */
        ResultsBoard.prototype.animateText = function (textField, dataObject, dataKey, initialValue, targetValue, delay) {
            var _this = this;
            textField.setText('' + initialValue);
            textField.alpha = 0;
            this.game.add.tween(textField)
                .to({ alpha: 1 }, 150, Phaser.Easing.Linear.None, true, delay);
            var duration = 200 + Math.pow(targetValue - initialValue, 0.92);
            dataObject[dataKey] = initialValue;
            var tweenObject = {};
            tweenObject[dataKey] = targetValue;
            var dataTween = this.game.add.tween(dataObject)
                .to(tweenObject, duration, Phaser.Easing.Linear.None, true, delay);
            dataTween.onUpdateCallback(function () {
                textField.text = '' + ~~dataObject[dataKey];
            });
            if (targetValue > initialValue) {
                dataTween.onStart.add(function () { return _this.countingSound.play(); });
            }
            dataTween.onComplete.add(function () {
                textField.text = '' + ~~dataObject[dataKey];
                _this.countingSound.stop();
            });
            return delay + duration + (duration > 200 ? 150 : 0);
        };
        ResultsBoard.prototype.fadeIn = function (target, duration, delay, text, callback) {
            if (text === void 0) { text = null; }
            if (text && target instanceof Phaser.Text) {
                target.setText(text);
            }
            target.alpha = 0;
            var tween = this.game.add.tween(target).to({ alpha: 1 }, duration, Phaser.Easing.Linear.None, true, delay);
            tween.onComplete.add(function() {
                if(callback && typeof callback === "function") {
                    callback();
                }
            }, this);
        };
        ResultsBoard.prototype.assignDoubleText = function (line, iconFrame, valueText, valueColor) {
            var icon = this.add(this.game.make.sprite(-106, line * 28 - 110, src.Settings.UI_ATLAS, iconFrame));
            icon.anchor.set(0, 0.5);
            var value = this.add(src.TextUtils.getShadowText(valueText, 115, line * 28 - 110, 24, valueColor, '#000000', 1, 2, 1));
            return [name, value];
        };
        ResultsBoard.prototype.assignTripleText = function (line, iconFrame, countText, valueText) {
            var icon = this.add(this.game.make.sprite(-106, line * 28 - 110, src.Settings.UI_ATLAS, iconFrame));
            icon.anchor.set(0, 0.5);
            var count = this.add(src.TextUtils.getShadowText(countText, 8, line * 28 - 110, 24, '#4BC9F3', '#000000', 1, 2, 0.5));
            var value = this.add(src.TextUtils.getShadowText(valueText, 115, line * 28 - 110, 24, '#8EE3FF', '#000000', 1, 2, 1));
            return [icon, count, value];
        };
        return ResultsBoard;
    }(Phaser.Group));
    src.ResultsBoard = ResultsBoard;
})(src || (src = {}));
var src;
(function (src) {
    var TransitionScreen = (function (_super) {
        __extends(TransitionScreen, _super);
        function TransitionScreen() {
            var _this = _super.call(this, src.App.instance, 0, 0, src.Settings.GAME_ATLAS, 'transitionScreen0000') || this;
            _this.isActive = false;
            _this.game.stage.addChild(_this);
            _this.inputEnabled = true;
            _this.visible = false;
            _this.tweenIn = _this.game.add.tween(_this)
                .to({ alpha: 1 }, src.Settings.TRANSITION_IN_DURATION, Phaser.Easing.Linear.None, false);
            _this.tweenOut = _this.game.add.tween(_this)
                .to({ alpha: 0 }, src.Settings.TRANSITION_OUT_DURATION, Phaser.Easing.Linear.None, false);
            _this.tweenOut.onComplete.add(_this.hide, _this);
            _this.resize();
            return _this;
        }
        TransitionScreen.prototype.resize = function () {
            this.scale.set(src.CustomScaleManager.WIDTH / (50 / 4), src.CustomScaleManager.HEIGHT / (50 / 4));
            this.position.set(-src.CustomScaleManager.WIDTH / 4, -src.CustomScaleManager.HEIGHT / 4);
        };
        TransitionScreen.prototype.start = function (callback) {
            this.game.stage.addChild(this);
            this.isActive = true;
            this.visible = true;
            this.alpha = 0;
            this.tweenIn.onComplete.removeAll();
            this.tweenIn.onComplete.add(function () { return (callback) ? callback() : null; });
            this.tweenIn.start();
        };
        TransitionScreen.prototype.finish = function () {
            this.tweenOut.start();
        };
        TransitionScreen.prototype.hide = function () {
            if (this.parent) {
                this.parent.removeChild(this);
            }
            this.tweenIn.onComplete.removeAll();
            this.isActive = false;
            this.visible = false;
        };
        return TransitionScreen;
    }(Phaser.Sprite));
    src.TransitionScreen = TransitionScreen;
})(src || (src = {}));
var src;
(function (src) {
    var LevelObject = (function () {
        function LevelObject(paths, tunnels, tension, resolution, platforms, balls, coinPlaces) {
            this.tension = src.Settings.DEFAULT_TENSION;
            this.resolution = src.Settings.POINTS_PER_SEGMENT;
            this.paths = [];
            this.tunnels = [];
            this.platforms = [];
            this.balls = [];
            this.coinPlaces = [];
            this.paths = paths || [];
            this.tunnels = tunnels || [];
            this.tension = tension;
            this.resolution = resolution;
            this.platforms = platforms || [];
            this.balls = balls || [];
            this.coinPlaces = coinPlaces || [];
        }
        return LevelObject;
    }());
    src.LevelObject = LevelObject;
})(src || (src = {}));
var src;
(function (src) {
    var LevelStorage = (function () {
        function LevelStorage() {
            this.savedLevels = null;
            this.buildLevels();
        }
        Object.defineProperty(LevelStorage, "instance", {
            get: function () {
                return LevelStorage._instance ? LevelStorage._instance
                    : LevelStorage._instance = new LevelStorage();
            },
            enumerable: true,
            configurable: true
        });
        LevelStorage.prototype.buildLevels = function () {
            this.savedLevels = JSON.parse('{"levels":[null,{"tension":0.5,"resolution":15,"paths":[[[38.95,123.7],[180.69,265.44],[309.54,208.57],[386.34,212.83],[474.52,281.1],[552.74,390.61],[582.61,512.92],[564.12,656.57],[498.7,773.19],[379.23,849.99],[235.59,849.99],[124.66,771.77],[64.92,646.61],[64.92,510.08],[111.86,407.68],[208.57,329.46],[329.46,313.81],[433.28,376.39],[490.17,488.74],[480.21,609.63],[426.17,713.46],[356.48,764.66],[281.1,764.66],[222.79,713.46],[202.88,673.63]]],"tunnels":[],"platforms":[[311.4666666666667,504.8888888888889]],"balls":[[3,3,5,5,3,3,3,6,7,3,3,7,7,3,5,3,6,7,7,3,6,7,7,7,5,7,6,6,5,7,7,6,6,5,5,5,3,5,5,7,3,3,7,7,3,6,6,5,5,3,3,3,5,7,7,5,5,7,3,3,6,6,3,5,5,5,6,6,5,7,6,6,6,7,7,6,6,3,3,6,5,5,5,6,7,7,7,3,3,3,7,5,6,6,6,5,5,3,3,7,7,7,6,5,5,6,6,6]],"coinPlaces":[[512.4688612099644,228.89679715302492],[140.08451957295372,904.1992882562279]]},{"tension":0.4,"resolution":10,"paths":[[[19.91,183.47],[316.66,182.97],[552.74,187.23],[558.43,258.34],[316.66,265.46],[83.41,276.83],[54.97,399.14],[63.08,531.41],[90.52,643.77],[136.03,710.61],[208.57,756.12],[303.86,756.12],[379.23,710.61],[429.01,623.86],[450.34,500.12],[474.52,353.63],[548.48,353.63],[572.66,508.66],[572.66,679.32],[548.48,838.61],[387.77,855.68],[221.37,852.83]]],"tunnels":[],"platforms":[[248.88888888888889,513.4222222222222]],"balls":[[6,3,3,5,5,3,3,3,3,5,6,6,6,7,7,7,6,3,3,5,5,5,6,3,3,6,6,7,7,7,6,7,7,6,6,7,5,5,5,7,7,7,7,5,3,5,6,6,6,3,3,3,6,5,5,5,5,6,6,6,6,7,7,6,5,3,3,3,5,5,3,7,7,3,3,3,3,7,5,5,7,3,7,6,6,7,5,5,7,7,7,7,3,6,6,7,7,5,3,3,5,5,5,5,3,7,7,3,3,6,6,6,6,7,5,6,6,5,5,3]],"coinPlaces":[[591.040925266904,340.4982206405694],[69.47508896797159,770.9608540925268]]},{"tension":0.4,"resolution":10,"paths":[[[25.1,200.04],[60.66,222.79],[66.34,279.68],[66.34,477.37],[66.34,683.59],[81.99,800.21],[144.57,859.94],[306.7,868.48],[450.34,858.52],[511.5,811.59],[517.19,693.54],[514.34,493.01],[509.16,298.67],[495.86,241.78],[452.27,209.07],[350.79,200.03],[252.66,208.57],[201.46,242.7],[182.04,298.67],[183.47,453.69],[183.47,582.61],[187.23,680.74],[215.68,714.88],[279.68,717.72]],[[578.34,859.94],[578.34,694.97],[576.92,485.9],[574.08,289.63],[558.43,208.57],[498.7,157.37],[366.43,144.57],[215.68,157.37],[147.41,208.57],[121.81,289.63],[121.81,468.83],[121.81,673.63],[137.46,751.86],[191.5,800.21],[288.21,811.59],[392.03,803.06],[446.08,768.92],[456.03,683.59],[451.77,493.01],[446.08,345.1],[424.74,302.43],[365.01,299.59]]],"tunnels":[],"platforms":[[318.5777777777778,494.93333333333334]],"balls":[[3,3,6,7,7,5,6,6,6,6,3,3,3,7,7,7,7,3,6,7,7,6,3,3,3,3,5,6,6,6,7,5,5,7,7,7,7,3,3,3,7,7,5,5,7,7,7,3,6,6,6,6,5,5,3,3,3,3,5,5,5,3,6,6,3,3,5,6,6,5,5,5,5,7,5,5,5,7,7,7,6,6,6,7,5,5,5,5,3,3,6,6],[6,6,3,3,5,5,5,5,7,6,6,6,7,7,7,5,5,5,7,5,5,5,5,6,6,5,3,3,6,6,3,5,5,5,3,3,3,3,5,5,6,6,6,6,3,7,7,7,5,5,7,7,3,3,3,7,7,7,7,5,5,7,6,6,6,5,3,3,3,3,6,7,7,6,3,7,7,7,7,3,3,3,6,6,6,6,5,7,7,6,3,3]],"coinPlaces":[[93.38967971530249,169.67971530249113],[511.32562277580075,923.5587188612101]]},{"tension":0.5,"resolution":10,"paths":[[[605.87,109.51],[539.94,195.77],[434.7,288.21],[286.79,377.82],[148.83,483.06],[79.14,653.72],[116.12,781.72],[198.61,851.41],[309.54,872.74],[438.97,840.03],[527.14,768.92],[569.81,689.28],[585.46,589.72],[579.77,477.37],[564.12,384.92],[521.46,282.52],[431.86,184.39],[312.39,148.83],[161.63,185.81],[73.46,305.28],[64.92,470.26],[134.61,591.14],[204.3,736.21],[262.61,794.52],[339.41,801.63],[424.74,777.46],[491.59,716.3],[518.61,652.3],[516.27,588.8],[493.01,515.77]]],"tunnels":[[0,10,3.8215046160431356,20,1.0129389528254849],[0,40,3.949940300695508,50,-0.12701372602866456]],"platforms":[[335.64444444444445,615.8222222222222]],"balls":[[3,5,7,7,5,5,5,7,7,7,7,6,6,7,3,3,5,6,7,7,5,5,7,6,6,6,5,6,6,6,3,6,6,6,7,7,7,6,5,6,6,3,5,5,5,3,3,3,6,7,3,3,3,7,7,3,3,5,5,5,5,6,7,3,3,7,7,3,5,5,3,6,6,3,3,6,7,7,7,5,5,7,6,6,6,6,3,5,5,6,5,7,7,7,5,7,3,3,3,3,6,3,3,5,5,5,6,6,5,5,7,6,6,7,7,3,3,3,5,3]],"coinPlaces":[[95.66725978647692,184.48398576512457],[505.6316725978648,906.4768683274023]]},{"tension":0.5,"resolution":10,"paths":[[[616.62,148.83],[493.88,148.83],[348.72,148.83],[219.94,148.83],[124.66,161.63],[70.61,200.03],[57.81,255.5],[97.63,305.28],[180.69,319.5],[330.88,258.34],[443.23,249.81],[541.37,305.28],[582.61,399.14],[572.66,511.5],[518.61,579.77],[433.28,608.21],[343.68,582.61],[279.68,510.08],[234.17,441.81],[173.88,406.21],[99.36,433.97],[64.92,510.08],[67.21,609.32],[84.75,696.99],[124.2,774.43],[189.95,831.42],[274.7,867.95],[401.83,876.71],[490.17,869.9],[544.21,842.88],[545.63,800.21],[499.23,771.01],[376.49,744.71],[268.36,696.49],[214.29,620.5]]],"tunnels":[],"platforms":[[429.5111111111111,429.5111111111111]],"balls":[[5,6,6,7,7,5,5,5,7,7,5,6,3,3,3,6,6,3,7,7,3,5,5,5,7,3,3,7,3,6,6,6,7,7,7,5,5,3,3,3,6,5,5,6,6,5,5,3,6,5,3,3,6,5,5,5,6,6,5,3,3,5,5,7,6,6,6,6,7,7,7,5,7,7,3,3,3,3,6,5,5,6,6,6,7,3,3,3,7,7,3,3,7,6,5,5,6,6,3,7,7,3,3,5,6,6,5,5,7,7,7,7,6,6,7,7,3,3,5,5,5,5,3,6,6,6,7,7,7,3,3,7]],"coinPlaces":[[47.83807829181496,178.7900355871886],[589.9021352313167,302.91814946619223]]},{"tension":0.5,"resolution":10,"paths":[[[278.26,913.99],[242.7,835.77],[212.83,743.33],[201.45,649.46],[212.83,565.55],[258.34,512.93],[356.48,502.97],[480.21,498.69],[524.3,444.65],[525.72,316.66],[514.34,234.17],[465.99,235.59],[463.15,320.92],[448.92,424.74],[346.52,440.39],[238.43,444.66],[170.17,493.01],[140.3,566.97],[137.46,687.86],[138.88,766.08],[143.14,808.74]],[[59.23,854.26],[59.23,615.82],[59.23,356.98],[67.77,218.52],[128.92,161.63],[322.34,151.68],[491.59,161.63],[562.7,205.72],[579.77,343.68],[579.77,588.3],[566.97,773.19],[529.99,838.61],[474.52,849.99]]],"tunnels":[],"platforms":[[267.37777777777774,288.7111111111112],[381.15555555555557,658.9555555555556]],"balls":[[5,7,7,7,6,6,6,6,7,7,6,3,3,6,6,3,5,5,3,3,3,3,6,6,6,3,3,5,5,7,3,5,5,6,7,7,7,7,5,6,6,5,5,5,5,7,7,6,6,6,3,3,6,6,7,5,5,5,5,3,3,3,6,6,6,6,7,7,7,3,3,5,5,3,7,7,5,3,3,3,3,7,7,5,5,5,6,6,5,5,5,7,7,7,7,3,3,3,6,7],[5,7,7,7,6,6,6,6,7,7,6,3,3,6,6,3,5,5,3,3,3,3,6,6,6,3,3,5,5,7,3,5,5,6,7,7,7,7,5,6,6,5,5,5,5,7,7,6,6,6,3,3,6,6,7,5,5,5,5,3,3,3,6,6,6,6,7,7,7,3,3,5,5,3,7,7,5,3,3,3,3,7,7,5,5,5,6,6,5,5,5,7,7,7,7,3,3,3,6,7]],"coinPlaces":[[48.97686832740214,176.51245551601426],[589.9021352313168,175.37366548042695]]},{"tension":0.5,"resolution":10,"paths":[[[20.46,733.52],[87.67,796.35],[180.69,848.45],[294.66,868.91],[420.82,862.1],[519.68,838.22],[579.59,788.54],[588.3,727.68],[557.01,687.86],[502.97,689.28],[443.23,720.57],[389.64,754.93],[318.04,772.47],[233.29,756.39],[162.19,714.52],[106.67,637.08],[63.5,528.57],[62.08,407.68],[94.79,291.06],[147.58,220.64],[213.33,173.88],[308.31,151.96],[426.67,165.11],[518.22,214.29],[568.4,293.7],[585.46,387.77],[571.23,500.12],[517.19,596.83],[424.74,649.46],[328.03,663.68],[236.71,628.31],[173.01,524.3],[177.28,384.92],[235.59,301.01],[326.61,273.99],[395.48,299.04]]],"tunnels":[],"platforms":[[320.53881278538813,467.57990867579906]],"balls":[[3,7,7,7,7,5,5,6,6,6,3,3,3,5,5,5,3,7,7,7,6,5,5,5,7,6,6,6,7,3,3,3,7,6,6,6,7,5,5,3,3,5,6,3,6,7,7,5,5,7,6,5,5,3,7,7,7,5,5,5,5,6,5,6,6,7,7,3,5,5,5,3,7,7,7,5,6,6,6,6,3,7,7,5,3,3,3,3,7,6,6,3,3,7,7,6,3,3,7,5,5,3,6,6,3,3,6,5,5,7,7,6,6,3,3,6,5,6,6,7,3,3,5,6,6,5,7,7,3,3,3,5]],"coinPlaces":[[50.11565836298932,693.523131672598],[67.19750889679716,204.98220640569397]]},{"tension":0.3,"resolution":10,"paths":[[[79.14,871.32],[81.99,710.61],[77.72,504.39],[117.54,410.52],[177.28,337.99],[177.28,184.39],[167.32,144.57],[66.34,144.57],[55.97,184.39],[59.23,276.83],[89.1,352.21],[174.43,552.74],[184.39,709.19],[191.5,813.01],[218.52,848.57],[312.39,858.52],[468.83,858.52],[539.94,848.57],[566.97,813.01],[568.39,683.59],[568.39,492.09],[568.39,294.4],[568.39,177.78],[539.94,153.1],[413.37,148.83],[278.76,153.1],[249.81,177.28],[249.81,211.41],[278.76,234.67],[411.94,235.59],[480.21,237.01],[500.12,259.77],[500.12,376.39],[500.12,486.4],[500.12,576],[500.12,712.03],[481.63,744.74],[401.99,744.74]]],"tunnels":[[0,20,0.0009817172027541954,40,3.190769283086818]],"platforms":[[339.9111111111111,494.93333333333334]],"balls":[[3,7,7,3,3,3,6,6,7,3,3,3,3,5,3,7,6,6,6,7,3,3,6,3,3,5,5,3,6,7,5,5,5,5,3,5,6,6,6,3,7,7,6,6,5,3,3,6,7,7,7,5,7,7,3,6,6,5,5,6,6,5,7,7,6,5,3,3,7,7,7,3,3,3,5,5,7,5,3,3,7,6,6,7,7,7,5,6,6,3,3,3,6,5,5,5,7,6,6,6,6,3,5,5,5,7,5,5,5,7,7,7,7,3,3,6,6,3,5,7,7,5,5,3,3,7,6,6,6,5,5,6,7,7,6,5,5,6,7,7,3,5,5,6]],"coinPlaces":[[53.5320284697509,448.68327402135236],[153.7455516014235,916.7259786476868]]},{"tension":0.5,"resolution":10,"paths":[[[184.39,933.9],[121.81,838.61],[74.88,707.77],[54.97,538.52],[64.92,366.43],[89.1,279.68],[121.81,225.63],[157.37,217.1],[170.17,246.97],[145.99,302.43],[126.08,376.39],[114.7,531.41],[134.61,694.97],[187.23,825.81],[227.06,840.03],[242.7,804.48],[201.46,679.32],[178.7,531.41],[205.72,379.23],[264.03,265.46]],[[518.61,99.06],[551.32,232.74],[576.92,389.19],[585.46,578.34],[566.97,749.01],[532.83,844.3],[497.28,857.1],[477.37,822.97],[510.08,727.68],[529.99,581.19],[520.03,397.72],[493.01,238.43],[458.88,214.26],[431.86,251.23],[456.03,404.83],[461.72,581.19],[431.86,709.19],[392.03,777.46]]],"tunnels":[],"platforms":[[329.15555555555557,522.5333333333333]],"balls":[[3,6,6,7,7,7,7,3,3,7,7,5,5,7,3,3,5,6,6,6,5,5,7,3,5,5,6,6,6,5,5,6,5,5,5,5,3,3,3,5,6,6,7,5,5,5,7,7,7,6,3,3,6,6,5,3,3,3,7,7,6,7,7,7,5,3,5,5,6,6,6,3,3,3,3,6,7,7,3,3,6,6,7,5,5,5,7,7,6,6,3,3,3,7,7,3,7,7,7,6,6,6,6,3,3,5,5,5],[5,5,5,3,3,6,6,6,6,7,7,7,3,7,7,3,3,3,6,6,7,7,5,5,5,7,6,6,3,3,7,7,6,3,3,3,3,6,6,6,5,5,3,5,7,7,7,6,7,7,3,3,3,5,6,6,3,3,6,7,7,7,5,5,5,7,6,6,5,3,3,3,5,5,5,5,6,5,5,6,6,6,5,5,3,7,5,5,6,6,6,5,3,3,7,5,5,7,7,3,3,7,7,7,7,6,6,3]],"coinPlaces":[[472.60676156583634,934.9466192170819],[74.03024911032031,190.1779359430605]]},{"tension":0.5,"resolution":10,"paths":[[[68.27,98.13],[80.57,202.88],[140.3,299.59],[269.72,376.39],[413.37,411.94],[529.99,380.66],[584.03,278.26],[534.26,164.48],[410.52,131.77],[305.28,187.23],[246.97,279.68],[248.39,407.68],[292.48,514.34],[335.14,596.83],[362.17,704.92],[329.46,811.59],[234.17,872.74],[130.34,857.1],[63.5,773.19],[54.97,623.86],[93.37,524.3],[187.23,463.14],[347.94,458.88],[465.99,517.19],[515.77,611.06],[522.88,719.14]]],"tunnels":[[0,100,3.589342730374907,120,-0.5016673573800157]],"platforms":[[425.24444444444447,268.8],[199.26666666666668,742.7777777777778]],"balls":[[3,7,6,6,6,7,3,5,5,5,3,7,7,3,6,7,3,3,5,7,7,3,3,6,6,7,5,5,7,7,6,6,6,7,3,3,7,7,5,6,6,5,7,7,5,6,3,6,6,5,3,3,3,5,5,5,3,3,3,6,6,3,5,5,3,3,6,5,6,3,3,7,7,7,3,6,5,6,6,5,5,3,3,7,3,5,5,6,6,7,5,3,3,3,6,6,6,5,5,7,7,5,5,7,6,5,3,3,5,5,5,6,3,6,7,5,5,7,7,7,5,3,7,6,6,7,7,6,5,5,7,6,6,5,6,7,7,3,3,7,7,7,6,3]],"coinPlaces":[[206.1298932384342,168.54092526690394],[402.00177935943066,879.1459074733096]]},{"tension":0.5,"resolution":10,"paths":[[[110.43,906.88],[232.74,804.48],[426.17,616.74],[561.28,429.01],[561.28,262.61],[431.86,188.66],[289.63,239.86],[140.3,400.57],[59.23,545.63],[66.34,645.19],[140.3,702.08],[254.08,685.01],[382.08,564.12],[491.59,410.52],[497.28,301.01],[409.1,259.77],[289.63,332.3],[181.54,467.41],[138.88,538.52],[133.19,578.34],[161.63,601.1],[215.68,575.5],[320.92,461.72]]],"tunnels":[],"platforms":[[479.2888888888889,819.2],[117.86666666666662,176.6222222222222]],"balls":[[5,7,6,6,6,3,6,5,5,3,7,7,3,5,3,3,6,6,3,7,3,5,5,6,5,7,7,5,5,5,3,7,3,3,6,5,5,7,7,5,5,5,7,3,3,5,3,6,7,7,7,5,3,6,6,6,5,3,3,3,3,7,7,5,6,6,5,5,6,5,7,7,3,3,3,7,7,6,6,6,6,3,3,7,7,7,3,3,6,6,3,7,3,3,3,7,6,6,5,5,7,7,6,5,3,3,3,6,5,5,7,7,7,7,5,5,5,7,6,6,3,3,6,5,5,6,6,5,3,3,6,7,7,5,5,5,5,7,6,6,3,3,6,6,3,7,7,7,5,5,7,6,6,6,7,6]],"coinPlaces":[[84.279359430605,776.6548042704627],[559.1548042704626,200.42704626334523]]},{"tension":0.3,"resolution":20,"paths":[[[56.89,854.26],[56.89,590.22],[56.89,310.04],[63.5,171.59],[131.77,171.59],[137.46,310.04],[141.72,590.22],[168.74,847.14],[416.21,835.77],[423.32,781.72],[299.59,760.39]],[[581.19,103.82],[581.19,310.04],[581.19,590.22],[574.08,831.5],[507.23,831.5],[495.86,590.22],[488.74,310.04],[461.72,160.21],[229.9,165.9],[221.37,218.52],[337.99,244.12]]],"tunnels":[],"platforms":[[322.4222222222222,497.7777777777777]],"balls":[[7,7,5,3,3,5,5,6,6,7,7,7,5,6,3,3,3,3,6,7,7,5,5,7,3,3,5,5,5,3,6,6,7,7,7,6,3,3,6,6,7,6,3,5,5,3,3,3,6,6,6,6,3,7,5,5,6,6,5,7,7,3,6,6,6,3,3,3,6,5,5,5,7,5,5,7,7,7,7,3,5,6,6,6,5,7,7,7,6,3,3,3,7,7,5,5,5,7,6,6,3,3,5,7,7,5,5,5,5,7,3,6,6,6,3,3],[3,3,6,6,6,3,7,5,5,5,5,7,7,5,3,3,6,6,7,5,5,5,7,7,3,3,3,6,7,7,7,5,6,6,6,5,3,7,7,7,7,5,5,7,5,5,5,6,3,3,3,6,6,6,3,7,7,5,6,6,5,5,7,3,6,6,6,6,3,3,3,5,5,3,6,7,6,6,3,3,6,7,7,7,6,6,3,5,5,5,3,3,7,5,5,7,7,6,3,3,3,3,6,5,7,7,7,6,6,5,5,3,3,5,7,7]],"coinPlaces":[[143.4964412811388,931.5302491103204],[507.90925266903923,163.9857651245552]]},{"tension":0.3,"resolution":10,"paths":[[[67.77,851.41],[67.77,723.41],[67.77,551.82],[67.77,357.9],[87.68,187.23],[249.81,167.32],[423.32,167.32],[557.01,187.23],[574.08,367.86],[574.08,628.12],[566.97,827.23],[501.54,871.32],[229.9,871.32],[177.28,824.39],[168.74,676.48],[168.74,505.81],[195.77,305.28],[453.19,306.7],[474.52,514.34],[461.72,716.3],[357.9,727.68]]],"tunnels":[],"platforms":[[321.4222222222222,456.53333333333336]],"balls":[[5,3,6,6,6,3,3,6,6,6,7,5,5,7,7,7,3,6,6,7,3,3,6,6,7,5,5,5,3,3,7,7,3,5,5,5,6,3,3,7,5,5,6,3,3,3,7,6,6,5,5,5,7,7,7,5,5,6,5,5,6,6,7,3,3,3,7,3,6,3,3,6,7,7,7,3,5,7,6,6,6,5,3,3,3,7,7,5,6,6,3,7,7,5,5,7,6,6,5,3,3,3,6,5,3,5,7,7,7,6,5,3,3,7,5,5,5,7,7,6,3,5,5,7,7,6,3,7,7,5,3,3,6,5,5,6,6,5,3,3,6,6,5,3,7,7,3,5,5,6,7,7,6,6,6,7]],"coinPlaces":[[47.83807829181495,177.65124555160145],[591.040925266904,175.37366548042706]]},{"tension":0.5,"resolution":10,"paths":[[[564.12,879.86],[501.54,783.14],[481.63,662.26],[510.08,538.52],[515.77,390.61],[491.59,278.26],[403.41,215.68],[273.99,158.79],[157.37,141.72],[75.45,202.31],[56.39,335.14],[53.2,497.78],[58.67,634.09],[76.59,742.98],[122.67,821.84],[201.46,861.37],[315.23,875.59],[461.72,858.52],[545.63,817.28],[562.7,693.54],[561.28,592.57],[578.34,465.99],[571.23,283.94],[542.79,174.43],[461.72,143.14],[319.5,167.32],[181.54,242.7],[126.08,336.57],[113.28,478.79],[116.12,609.63],[130.34,706.34],[160.21,757.54],[211.41,749.01],[268.8,651.38],[318.08,630.97],[359.32,653.72],[370.7,694.97]]],"tunnels":[[0,170,1.4042197002223553,190,3.116138161842794],[0,60,-1.055535939944661,80,1.1107215169449334]],"platforms":[[317.15555555555557,428.0888888888889]],"balls":[[7,6,3,3,5,5,5,6,5,6,6,5,3,3,7,7,3,5,6,5,5,7,6,3,3,7,6,6,3,5,5,7,7,6,6,7,6,5,5,7,7,5,3,3,5,5,3,3,3,7,7,7,6,3,5,7,7,5,7,7,6,7,3,5,5,5,3,5,3,7,7,6,6,6,3,7,7,7,3,5,5,7,7,7,5,6,6,7,3,3,3,5,5,7,6,6,7,3,3,3,6,5,7,7,6,5,5,3,3,5,6,6,3,6,5,6,6,6,7,6,6,3,3,5,5,3,7,6,6,6,3,7,3,3,5,7,6,6,7,7,6,3,5,5,6,7,6,6,3,3,5,5,5,3,7,7,6,3,3,5,3,3,5,5,7,7,6,6]],"coinPlaces":[[592.1797153024911,177.65124555160145],[134.3861209964413,929.252669039146]]},{"tension":0.5,"resolution":10,"paths":[[[56.39,855.68],[53.54,548.48],[87.68,470.26],[205.72,453.19],[326.61,411.94],[463.14,325.19],[510.08,343.68],[502.54,396.3],[387.77,477.37],[259.77,529.99],[136.03,569.81],[109.01,692.12],[131.77,777.46],[170.17,814.43],[205.72,827.23]],[[109.01,94.79],[170.17,160.21],[275.41,182.97],[362.17,293.9],[474.52,508.66],[487.32,569.81],[494.43,825.81],[574.08,821.54],[584.03,544.21],[575.5,261.19],[541.37,207.14]]],"tunnels":[[1,30,2.575216080344406,40,-0.24968952651585008]],"platforms":[[152.17777777777775,302.93333333333334],[312.8888888888889,667.0222222222225]],"balls":[[7,5,5,7,7,5,6,3,3,3,6,6,3,5,7,7,6,6,3,3,3,3,5,5,7,6,6,6,7,7,7,7,6,5,3,3,5,5,7,7,7,5,3,3,5,7,6,6,5,5,5,6,7,7,7,3,6,6,6,5,3,3,3,7,3,7,7,6,6,6,6,3,3,3,6,5,5,7,7,7,6,3,5,5,5,5,7,7,6,6,6,7,7,5,5,5,6,6,5,5,3,3,7,3,6,6,3,3,5,5,3,7,7,3,3,7,6,5,5,5,3,3,6,6],[6,6,3,3,5,5,5,6,7,3,3,7,7,3,5,5,3,3,6,6,3,7,3,3,5,5,6,6,5,5,5,7,7,6,6,6,7,7,5,5,5,5,3,6,7,7,7,5,5,6,3,3,3,6,6,6,6,7,7,3,7,3,3,3,5,6,6,6,3,7,7,7,6,5,5,5,6,6,7,5,3,3,5,7,7,7,5,5,3,3,5,6,7,7,7,7,6,6,6,7,5,5,3,3,3,3,6,6,7,7,5,3,6,6,3,3,3,6,5,7,7,5,5,7]],"coinPlaces":[[128.6921708185053,915.5871886120996],[396.30782918149475,169.67971530249113]]},{"tension":0.5,"resolution":10,"paths":[[[63.5,99.06],[63.5,176.3],[63.5,282.01],[63.5,424.71],[63.5,569.36],[63.5,668.72],[67.77,770.34],[86.26,842.88],[133.19,842.88],[151.68,770.34],[151.68,668.72],[151.68,569.36],[151.68,424.71],[153.1,282.01],[171.59,197.19],[228.48,161.63],[291.06,173.01],[322.34,227.06],[325.19,298.17],[303.86,352.21],[244.12,424.71],[215.68,565.54],[234.17,668.72],[306.7,726.26],[413.37,729.1],[494.43,668.72],[515.77,559.86],[490.17,423.32],[438.97,346.52],[413.37,295.32],[413.37,219.94],[448.92,171.59],[508.66,157.37],[557.01,187.23],[579.77,269.72],[584.03,409.1],[585.46,552.74],[584.03,676.48],[566.97,768.92],[504.39,814.43],[411.94,820.12],[320.92,820.12]]],"tunnels":[],"platforms":[[364.0888888888889,533.3333333333334]],"balls":[[4,4,7,7,7,6,6,7,4,3,3,5,6,6,5,5,3,7,4,4,7,7,4,6,5,5,6,5,3,5,5,3,3,6,6,6,3,7,7,7,7,3,3,7,7,5,5,5,6,6,7,7,4,4,7,7,7,5,6,4,4,4,3,3,4,6,6,4,4,3,7,5,5,5,7,7,5,3,3,3,6,6,3,3,3,6,5,5,4,7,7,6,6,6,7,7,4,5,5,4,4,4,4,3,3,6,5,5,6,6,3,7,7,5,6,6,5,5,4,7,7,7,4,4,3,3,7,5,5,5,5,7,7,6,3,3,3,5,5,7,4,4,4,7,3,5,4,4,4,6,3,3,3,3,6,6,5,4,4,5,5,5,4,7,6,6,6,6,4,4,3,3,4,4,3,6,6,6,3,3]],"coinPlaces":[[154.8843416370107,159.43060498220643],[185.6316725978648,896.2277580071175],[591.040925266904,178.7900355871886]]},{"tension":0.5,"resolution":10,"paths":[[[20.83,138.88],[89.1,170.17],[157.37,255.5],[168.74,400.57],[126.08,572.66],[140.3,776.03],[305.28,825.81],[470.26,791.68],[525.72,672.21],[534.26,498.7],[511.5,286.79],[420.48,202.88],[212.83,200.03],[118.97,234.17],[87.68,306.7],[87.68,409.1],[66.34,575.5],[80.57,805.9],[191.5,869.9],[416.21,871.32],[542.79,813.01],[584.03,623.86],[576.92,347.94],[535.68,140.3],[465.99,127.5],[420.48,178.7],[433.28,286.79],[460.3,410.52],[477.37,518.61],[471.68,640.92],[420.48,749.01],[316.66,771.77],[195.77,730.52],[191.5,569.81],[256.92,414.79]]],"tunnels":[[0,120,4.635858930822183,140,-0.00882622420962731],[0,230,-0.2978293415558102,260,-0.21088232032108256]],"platforms":[[320,590.2222222222223]],"balls":[[4,6,3,3,4,4,3,7,7,3,3,7,6,5,5,5,5,6,6,5,4,3,3,4,4,4,4,7,7,6,6,7,4,4,4,5,5,4,6,6,4,4,6,5,3,3,3,6,6,7,5,7,7,7,5,5,7,6,5,5,4,3,3,3,4,5,6,6,5,5,5,7,7,4,3,5,5,3,4,4,7,7,7,5,5,4,6,4,4,3,5,7,7,5,6,6,6,6,5,3,7,7,3,3,3,7,6,7,4,4,4,3,5,4,7,6,6,6,7,7,7,3,5,5,4,3,3,4,4,5,5,4,7,7,7,7,6,7,3,4,4,4,6,6,6,7,7,6,5,5,5,3,6,6,3,3,3,3,6,4,4,7,3,3,5,5,5,3,3,5,4,4,3,7,7,6,6,6,7,5,3,3,5,5,6,6,7,7,6,6,4,4,3,3,6]],"coinPlaces":[[53.5320284697509,256.2277580071175],[591.0409252669041,854.0925266903917],[433.8879003558719,162.846975088968]]},{"tension":0.5,"resolution":10,"paths":[[[69.69,100.98],[69.69,189.16],[69.69,275.91],[69.69,368.36],[69.69,445.16],[69.69,556.09],[69.69,672.71],[69.69,777.96],[91.94,824.39],[138.88,824.39],[161.63,777.96],[161.63,672.71],[161.63,556.09],[160.21,441.81],[161.63,368.36],[161.63,245.54],[175.86,184.39],[221.37,153.1],[262.61,154.52],[296.74,187.23],[308.12,232.74],[309.54,273.99]],[[569.81,859.94],[569.81,770.84],[569.81,682.67],[569.81,584.53],[569.81,483.56],[569.81,382.58],[569.81,312.89],[569.81,233.24],[549.9,177.28],[502.97,175.86],[481.63,232.74],[481.63,312.89],[481.63,382.58],[481.63,483.56],[481.63,581.19],[481.63,682.67],[481.63,770.84],[457.46,830.08],[417.63,858.52],[372.12,858.52],[330.88,827.23],[318.08,780.3],[316.66,726.26]]],"tunnels":[],"platforms":[[320.00000000000006,499.20000000000005]],"balls":[[5,7,7,3,4,4,4,4,3,3,4,5,5,6,3,3,3,3,5,7,4,4,7,7,7,7,4,7,7,3,5,5,5,5,4,6,6,4,4,7,6,6,6,6,3,3,6,7,7,7,3,5,4,4,4,5,5,5,6,6,3,5,5,3,3,3,7,6,6,7,7,7,7,6,5,5,6,6,5,3,3,3,3,6,6,6,3,7,7,3,3,7,4,4,4,4,6,7,7,6,6,6,4,4,6,5,5,5,6,6,6,6,5,4,4,4,5,5,5,5,4,3,3,3,4,5,5,4,4,7,7,7,3,3,7],[7,3,3,7,7,7,4,4,5,5,4,3,3,3,4,5,5,5,5,4,4,4,5,6,6,6,6,5,5,5,6,4,4,6,6,6,7,7,6,4,4,4,4,7,3,3,7,7,3,6,6,6,3,3,3,3,5,6,6,5,5,6,7,7,7,7,6,6,7,3,3,3,5,5,3,6,6,5,5,5,4,4,4,5,3,7,7,7,6,3,3,6,6,6,6,7,4,4,6,6,4,5,5,5,5,3,7,7,4,7,7,7,7,4,4,7,5,3,3,3,3,6,5,5,4,3,3,4,4,4,4,3,7,7,5]],"coinPlaces":[[490.8274021352314,917.8647686832741],[156.0231316725978,159.43060498220643],[136.66370106761568,920.1423487544484]]},{"tension":0.4,"resolution":10,"paths":[[[69.19,99.06],[72.03,221.37],[96.21,342.26],[226.63,354.9],[423.32,352.21],[557.01,353.63],[579.77,386.34],[557.01,419.06],[419.06,424.74],[231.32,427.59],[87.68,434.7],[57.81,468.83],[83.41,502.97],[234.17,505.81],[420.48,501.54],[557.01,504.39],[579.77,538.52],[557.01,571.23],[424.74,575.5],[234.17,579.77],[87.68,585.46],[57.39,623.86],[87.68,656.57],[234.17,656.57],[427.59,653.72],[555.59,656.57],[578.34,690.7],[548.48,751.86]]],"tunnels":[],"platforms":[[318.53333333333336,208.42222222222222],[320,807.8222222222223]],"balls":[[3,6,6,6,3,3,6,4,4,4,4,7,5,5,7,7,7,5,4,3,6,6,7,3,3,6,6,7,4,5,5,5,4,4,5,7,7,7,7,4,3,3,7,6,6,6,7,7,6,5,5,3,7,7,3,5,4,4,6,6,4,7,3,3,7,7,5,6,6,6,6,5,5,6,3,4,4,4,3,5,7,7,6,5,4,4,7,7,4,5,5,5,7,6,6,6,3,7,4,4,4,7,7,3,3,5,3,5,5,5,5,3,3,3,5,7,7,6,6,7,6,6,4,4,4,5,5,6,3,3,3,3,6,6,3,5,7,4,4,7,7,7,4,6,3,3,6,4,4,3,3,3,4,4,6,6,4,3,3,5,5,3,6,5,5,4,4,7,7,7,5,5,5,7,4,6,6,4,7,7,5,3,3,3,5,5,6,4,4,6,5,5,4,3,3]],"coinPlaces":[[48.976868327402144,413.38078291814946],[46.69928825622777,577.3665480427045]]},{"tension":0.5,"resolution":10,"paths":[[[535.68,895.5],[395.48,864.52],[238.43,857.1],[101.9,807.32],[59.23,636.66],[49.28,480.21],[56.39,350.79],[87.68,245.27],[165.91,173.59],[319.5,154.82],[474.52,173.59],[552.74,245.27],[579.77,345.1],[588.3,484.48],[584.03,635.23],[570.82,730.09],[525.72,754.7],[484.48,721.99],[481.63,636.66],[475.94,485.9],[453.19,309.54],[374.97,246.97],[246.97,251.23],[169,310.73],[141.72,414.79],[136.03,505.81],[145.99,613.9],[184.39,706.34],[252.66,734.79]]],"tunnels":[],"platforms":[[312.6940639269406,450.0456621004566]],"balls":[[6,6,4,7,7,3,4,4,4,3,3,3,4,6,7,7,7,3,5,5,5,3,3,4,6,6,7,6,5,5,6,7,7,7,4,4,7,3,3,3,7,3,6,6,6,7,3,5,4,4,5,5,5,5,4,3,3,6,6,3,4,4,4,6,6,6,5,4,4,4,5,3,3,5,5,4,6,4,7,7,4,4,5,3,3,3,4,7,6,6,6,3,5,5,5,3,3,3,3,6,4,4,4,4,3,3,3,4,7,6,6,7,7,7,5,5,5,4,4,5,7,7,7,3,6,6,6,3,3,3,5,5,5,7,6,4,7,7,4,4,4,5,7,7,5,3,6,7,7,7,4,3,3,3,6,5,5,6,6,6,3,5,3,3,5,5,7,7,7,6,6,6,7,7,5,5,4,4,3,7,5,6,6,6,6,5,5,5,6,7,4,4,4,7,7,7,7,3,3,6,6,5,4,4,4,5,5,5,6,7]],"coinPlaces":[[140.08007117437722,931.5302491103205],[55.80960854092527,181.06761565836302],[583.0693950177937,181.067615658363]]},{"tension":0.5,"resolution":10,"paths":[[[615.32,207.14],[532.83,164.48],[417.63,147.41],[278.26,161.63],[145.99,221.37],[67.77,347.94],[69.19,548.48],[187.23,677.9],[241.28,766.08],[345.1,808.74],[471.68,808.74],[531.41,758.97],[537.1,686.43]],[[609.63,771.77],[512.92,848.57],[393.46,872.74],[252.66,848.57],[150.26,798.79],[89.1,692.12],[130.34,447.5],[150.26,342.26],[218.52,264.03],[335.14,218.52],[465.99,222.79],[529.99,275.41],[535.68,352.21]]],"tunnels":[[1,50,-0.3185186545544194,60,3.2720960374784385]],"platforms":[[384,507.73333333333335]],"balls":[[7,6,6,6,6,7,7,6,7,7,7,5,3,3,3,5,5,5,6,6,3,4,4,4,3,3,6,3,3,4,6,6,4,4,4,4,7,7,7,6,6,6,7,4,4,3,3,6,6,6,3,3,3,5,5,3,6,6,5,4,4,4,3,3,3,5,5,3,7,7,7,5,5,5,7,7,4,4,4,5,5,5,7,7,7,7,4,5,5,4,4,4,6,7,7,6,6,6,7,4,4,4,5,5,5,5,4,5,3,3,3,6,6,6,5,5,5,6,3,7,7,7,3,3,3,3,7,4,5,5,5,4,4,5,3,3,3,4,4,7,7,7,6,6,6],[7,6,6,6,6,7,7,6,7,7,7,5,3,3,3,5,5,5,6,6,3,4,4,4,3,3,6,3,3,4,6,6,4,4,4,4,7,7,7,6,6,6,7,4,4,3,3,6,6,6,3,3,3,5,5,3,6,6,5,4,4,4,3,3,3,5,5,3,7,7,7,5,5,5,7,7,4,4,4,5,5,5,7,7,7,7,4,5,5,4,4,4,6,7,7,6,6,6,7,4,4,4,5,5,5,5,4,5,3,3,3,6,6,6,5,5,5,6,3,7,7,7,3,3,3,3,7,4,5,5,5,4,4,5,3,3,3,4,4,7,7,7,6,6,6]],"coinPlaces":[[72.8914590747331,200.42704626334523],[140.08007117437722,901.9217081850535]]},{"tension":0.5,"resolution":10,"paths":[[[69.19,97.63],[67.77,275.41],[76.3,419.06],[134.61,487.32],[319.5,494.43],[495.86,485.9],[569.81,420.48],[569.81,234.17],[512.92,168.74],[379.23,154.52],[239.86,168.74],[181.54,242.7],[182.97,411.94],[182.97,619.59],[182.97,766.08],[221.37,851.41],[367.86,868.48],[511.5,849.99],[568.39,785.99],[568.39,619.59],[495.86,558.43],[316.66,548.48],[145.99,558.43],[90.52,622.43],[76.3,700.66],[83.41,749.01]]],"tunnels":[[0,120,3.1026342694936093,130,0.027947429375465793]],"platforms":[[385.4222222222222,325.6888888888889],[389.6888888888889,705.4222222222222]],"balls":[[6,5,4,4,4,6,6,6,4,5,7,7,5,5,5,7,7,5,6,3,3,3,6,6,3,7,7,3,3,6,3,7,4,5,5,3,4,4,3,3,3,4,5,6,5,5,6,6,3,6,5,3,3,5,5,5,3,6,5,3,3,5,4,4,4,5,5,4,3,7,6,4,4,4,7,7,7,4,6,6,6,6,7,7,6,3,5,5,3,3,3,3,5,7,4,6,6,4,4,4,4,6,6,6,4,5,7,7,7,5,5,5,5,7,3,3,6,5,5,6,6,4,3,7,7,3,3,7,4,4,6,5,5,6,6,4,5,5,7,4,4,7,7,7,7,4,4,7,5,3,3,3,6,6,3,5,5,5,5,3,7,7,6,6,6,7,5,3,3,5,5,5,3,3,7,4,4,4,4,7,7,7,4,4,6,6,6,6,4,4,7,6,3,3,3,3,4,4,3,7,6,6,7,7,7,7,4,7,7,4]],"coinPlaces":[[591.040925266904,175.37366548042715],[191.32562277580072,160.56939501779362]]},{"tension":0.5,"resolution":10,"paths":[[[18.49,105.24],[113.28,345.1],[217.1,465.99],[339.41,494.43],[456.03,460.3],[528.57,380.66],[547.06,283.94],[501.54,190.08],[409.1,145.99],[286.79,151.68],[208.57,198.61],[181.54,285.37],[212.83,367.86],[282.52,413.37],[387.77,410.52],[464.57,345.1],[456.03,249.81],[367.86,214.26],[268.3,282.52],[118.97,467.41],[97.63,582.61],[97.63,676.48],[124.23,761.81],[188.66,827.23],[298.17,858.52],[414.79,849.99],[504.39,790.26],[534.26,719.14],[536.26,700.66]]],"tunnels":[[0,180,3.965605435632515,190,0.30612614991035514]],"platforms":[[339.91111111111115,644.2666666666667]],"balls":[[6,3,3,6,6,6,7,5,5,4,7,7,7,4,4,3,6,6,7,3,3,6,6,7,5,5,5,3,3,7,7,3,5,5,5,6,3,3,6,6,6,3,4,5,5,5,5,4,4,4,5,3,3,3,7,7,5,5,5,6,6,5,5,6,7,7,7,4,4,4,7,6,6,6,4,4,5,5,5,4,3,3,3,4,4,4,3,3,3,4,7,3,6,4,3,3,4,4,4,6,7,7,7,5,6,6,6,3,5,5,3,3,3,5,7,4,4,7,7,5,4,6,6,7,4,4,7,7,7,7,4,5,5,6,3,3,3,4,4,3,6,6,5,3,5,7,7,7,4,4,4,7,5,5,5,7,7,6,4,4,4,4,3,4,3,3,3,3,4,4,5,7,7,7,5,5,6,6,7,3,3,7,7,3,3,3,6,5,5,5,6,6,6,6,5,3,3,4,4,3,5,5,4,7,7,6,6,6,7,7,5,6,6,5,5,7,7,7,6,4,4,4,6,6,6]],"coinPlaces":[[165.13345195729536,176.5124555160144],[587.6245551601424,371.2455516014235]]},{"tension":0.5,"resolution":10,"paths":[[[64,103.32],[64,291.06],[64,479.29],[64,681.24],[76.3,801.63],[121.81,851.41],[261.69,861.37],[384.92,861.37],[515.77,851.41],[565.54,801.63],[578.34,681.24],[578.34,479.29],[578.34,291.06],[544.21,219.94]],[[440.39,100.48],[367.86,218.52],[342.26,301.01],[342.26,441.81],[352.21,544.21],[400.57,599.68],[469.96,629.26],[515.77,676.48],[515.77,751.87],[447.5,798.79],[195.77,798.79],[127.5,747.31],[127.5,676.48],[172.45,629.26],[234.17,599.68],[285.37,544.21],[296.74,440.39],[293.9,301.01],[259.77,218.52]]],"tunnels":[],"platforms":[[176.35555555555558,402.488888888889],[465.06666666666666,402.48888888888894]],"balls":[[5,6,6,6,5,5,6,7,7,7,3,3,7,4,4,4,3,4,4,6,6,6,3,3,3,7,7,5,5,5,7,7,7,7,6,6,7,3,3,3,3,4,6,6,6,4,4,4,4,5,5,5,4,6,5,5,5,7,7,7,3,3,3,5,5,6,6,6,6,3,3,4,4,4,4,3,3,4,5,6,6,6,5,5,4,4,7,7,3,3,3,7,7,7,5,5,5,5,7,4,4,3,3,4,4,4,3,6,5,5,6,6,6,6,3,7,7,7,7,6,6,7,7,3,3,3,3,7,7,4,4,5,5,5,4,4,4,6,6,4,4,4,7,7,7,5,6,6,5,5,5,5,3,3,3],[5,6,6,6,5,5,6,7,7,7,3,3,7,4,4,4,3,4,4,6,6,6,3,3,3,7,7,5,5,5,7,7,7,7,6,6,7,3,3,3,3,4,6,6,6,4,4,4,4,5,5,5,4,6,5,5,5,7,7,7,3,3,3,5,5,6,6,6,6,3,3,4,4,4,4,3,3,4,5,6,6,6,5,5,4,4,7,7,3,3,3,7,7,7,5,5,5,5,7,4,4,3,3,4,4,4,3,6,5,5,6,6,6,6,3,7,7,7,7,6,6,7,7,3,3,3,3,7,7,4,4,5,5,5,4,4,4,6,6,4,4,4,7,7,7,5,6,6,5,5,5,5,3,3,3]],"coinPlaces":[[420.22241992882573,735.6583629893239],[223.21174377224202,739.0747330960854]]},{"tension":0.4,"resolution":10,"paths":[[[173.01,935.32],[173.01,865.63],[185.81,712.03],[299.59,680.74],[481.63,667.94],[521.46,549.9],[521.46,363.59],[502.97,246.97],[393.46,219.94],[235.59,225.63],[131.77,252.66],[117.54,370.7],[117.54,596.83],[140.3,714.88],[262.61,756.12],[420.48,758.97],[551.32,714.88],[578.34,551.32],[576.92,328.03],[552.74,190.08],[407.68,155.94],[235.59,155.94],[86.26,190.08],[60.66,370.7],[60.66,596.83],[97.63,767.5],[265.46,815.86],[423.32,838.61]]],"tunnels":[[0,10,0.0006950604534765592,30,4.684558503676588]],"platforms":[[311.4666666666667,450.84444444444443]],"balls":[[5,3,3,5,7,3,3,3,7,7,3,6,6,7,4,4,4,6,5,5,6,6,5,5,5,6,4,3,6,3,3,3,3,7,5,7,7,7,3,3,7,5,6,5,5,3,4,6,6,6,6,4,4,6,3,7,5,5,3,7,7,7,3,6,6,3,3,3,6,4,4,4,4,5,5,4,3,7,7,3,3,7,6,4,5,5,5,5,4,3,7,4,4,4,5,7,3,3,3,7,6,3,3,3,5,5,5,3,6,6,6,3,5,5,6,7,7,7,6,6,6,4,4,6,6,6,4,7,5,5,5,7,7,5,4,3,3,4,4,3,7,6,6,4,7,7,7,7,4,4,5,6,5,5,5,6,7,7,6,6,6,4,7,7,4,4,4,5,4,6,4,4,5,4,7,5,3,3,3,5,5,5,3,4,4,4,6,6,6,4,7,7,7,4,4,4,7,5,3,3,6,5,5,4,6,6,5,7,7,7,6,5,3,7,6,6,7,7,4,3,3,4,4,3,5]],"coinPlaces":[[581.9306049822064,822.2064056939502],[588.7633451957296,177.65124555160145],[48.97686832740214,175.37366548042706]]},{"tension":0.5,"resolution":10,"paths":[[[117.54,939.59],[275.41,780.3],[264.03,717.72],[144.57,744.74],[67.77,703.5],[56.39,601.1],[56.39,477.36],[56.39,360.74],[59.23,261.19],[95.29,186.31],[197.19,158.79],[318.07,153.1],[441.81,160.22],[553.25,180.62],[553.25,236.08],[438.97,238.93],[318.07,238.93],[200.03,246.04],[198.61,304.36],[318.07,311.46],[438.97,315.73],[539.02,325.69],[576.92,367.86],[578.35,494.43],[578.35,616.74],[565.55,709.18],[504.39,744.74],[387.77,717.72],[366.43,754.7],[410.52,814.43]]],"tunnels":[],"platforms":[[322.84444444444443,521.9555555555555]],"balls":[[5,6,7,6,6,6,4,4,4,4,6,4,5,5,7,7,7,5,6,6,7,4,4,3,6,6,3,3,4,7,5,5,5,5,7,7,6,3,3,5,6,6,5,5,4,4,4,5,3,3,4,4,3,6,6,7,5,5,5,7,7,7,7,5,5,5,7,6,5,3,3,5,7,7,5,5,6,6,5,4,3,3,3,4,4,7,3,6,6,7,3,3,5,7,7,7,5,5,6,3,3,6,6,6,6,7,4,7,7,4,4,3,3,3,7,7,4,4,7,5,5,6,6,5,4,7,7,4,4,4,3,3,3,3,4,6,6,6,3,3,3,6,4,4,3,7,7,7,6,3,5,4,4,4,3,3,3,4,6,5,5,3,7,7,5,5,3,6,3,3,7,4,4,7,7,5,5,5,4,7,7,7,5,7,4,4,4,6,5,5,4,3,3,4,6,6,6,4,4,6,3,3,4,4,3,5,7,7,5,5,6,6,6,7,7,6,6,3,5,5,6,3,4,6,6,4,4,7,3,6,6,3,3,4,5,5,5,7,7,3]],"coinPlaces":[[78.58540925266905,826.761565836299],[45.560498220640575,175.373665480427],[593.3185053380784,176.51245551601426]]},{"tension":0.5,"resolution":10,"paths":[[[23.68,531.41],[234.17,521.46],[413.37,522.88],[447.5,551.32],[413.37,575.5],[228.48,592.57],[106.17,626.7],[57.81,730.52],[109.01,832.92],[225.63,877.01],[369.28,847.14],[454.61,737.63],[512.92,568.39],[589.72,393.46],[578.34,266.88],[545.63,208.57]],[[20.83,468.83],[231.32,471.68],[413.37,465.99],[447.5,438.97],[413.37,414.79],[251.23,407.68],[106.17,383.5],[57.81,286.79],[109.01,180.12],[225.63,136.03],[369.28,164.48],[458.88,249.81],[520.03,407.68],[566.97,613.9],[562.7,716.3],[528.57,790.26]]],"tunnels":[[1,120,2.8366097741486183,130,-0.029872232291044964]],"platforms":[[264.53333333333336,732.4444444444445],[254.57777777777778,273.06666666666666]],"balls":[[6,6,5,5,5,7,7,5,3,3,3,7,7,3,3,7,4,7,7,7,7,4,4,6,6,6,4,4,4,5,5,5,4,6,6,6,6,4,4,7,3,3,3,3,7,7,6,3,4,4,4,4,3,3,5,5,5,7,7,7,5,5,6,6,4,4,4,4,6,6,4,5,5,5,3,3,3,3,5,5,6,6,4,4,7,7,7,6,6,6,5,5,3,3,5,5,5,5,3,6,6,6,3,3,3,6,7,4,4,7,7,7,7,5,4,4,4,5,5,7,7,7,3,6,6,3,3,3,7,7,5,5,5,5,7,7,5,6,6,6,3,3,3,4,4,5,5,4,4,4,3,3,7,7,7,3,3,6,6,6,6,4,4,4,6],[6,6,5,5,5,7,7,5,3,3,3,7,7,3,3,7,4,7,7,7,7,4,4,6,6,6,4,4,4,5,5,5,4,6,6,6,6,4,4,7,3,3,3,3,7,7,6,3,4,4,4,4,3,3,5,5,5,7,7,7,5,5,6,6,4,4,4,4,6,6,4,5,5,5,3,3,3,3,5,5,6,6,4,4,7,7,7,6,6,6,5,5,3,3,5,5,5,5,3,6,6,6,3,3,3,6,7,4,4,7,7,7,7,5,4,4,4,5,5,7,7,7,3,6,6,3,3,3,7,7,5,5,5,5,7,7,5,6,6,6,3,3,3,4,4,5,5,4,4,4,3,3,7,7,7,3,3,6,6,6,6,4,4,4,6]],"coinPlaces":[[50.11565836298933,621.779359430605],[50.11565836298932,439.5729537366549]]},{"tension":0.5,"resolution":10,"paths":[[[473.1,936.74],[532.83,798.79],[571.23,623.86],[571.23,457.46],[532.83,319.5],[473.1,200.03],[417.63,148.83],[346.52,144.57],[305.28,187.23],[305.28,234.17],[337.99,278.26],[421.9,342.26],[487.32,463.14],[487.32,623.86],[437.54,798.79],[393.46,861.37],[318.08,868.48],[275.41,837.19],[271.14,787.41],[301.01,743.32],[370.7,699.23],[401.99,623.86],[406.26,465.99],[337.99,377.81],[251.23,329.46],[222.79,275.41],[214.26,208.57],[194.34,157.37],[143.14,140.3],[86.26,157.37],[58.81,214.26],[56.39,308.12],[56.39,440.39],[54.97,582.61],[56.39,706.34],[59.23,760.39],[76.3,818.7],[107.59,848.57],[148.83,848.57],[177.28,811.59],[178.7,761.81]]],"tunnels":[],"platforms":[[208.9497716894977,489.49771689497715]],"balls":[[6,7,4,6,6,6,4,4,4,7,5,5,7,7,7,5,5,5,5,3,4,4,3,3,3,3,6,6,4,3,3,6,6,7,5,5,5,5,6,6,7,7,7,6,3,3,4,4,4,4,5,6,6,5,5,6,3,3,4,6,6,4,4,7,5,5,5,7,7,7,7,5,5,3,3,3,5,6,5,7,7,5,5,4,6,6,4,4,4,5,7,3,3,3,7,3,6,6,3,3,7,7,7,3,3,6,6,6,6,4,7,7,4,4,4,3,3,3,7,7,3,5,6,5,5,6,6,5,7,7,4,3,3,3,3,5,5,5,4,4,5,6,6,6,4,4,3,7,7,7,6,3,5,5,3,3,4,4,7,5,5,5,7,7,5,5,6,4,4,4,4,3,3,4,7,7,3,5,5,5,7,7,3,6,6,6,3,3,5,7,7,5,5,3,4,4,4,6,6,6,4,7,4,4,4,3,5,5,5,4,4,5,3,3,3,6,6,6,6,7,4,4,6,7,7,7,3,3,3,4,4,6,7,7,7,7,4,6,6,6]],"coinPlaces":[[559.1548042704627,203.84341637010678],[586.4857651245552,837.0106761565838],[248.26512455516016,165.1245551601424]]},{"tension":0.3,"resolution":10,"paths":[[[81.07,873.24],[217.1,865.63],[367.86,852.83],[491.59,831.5],[532.83,790.26],[555.59,655.14],[565.54,531.41],[527.14,502.97],[339.91,585.96],[101.9,697.81],[76.3,638.08],[328.03,515.77],[549.9,411.94],[528.57,350.79],[310.97,447.5],[118.97,528.57],[74.88,501.54],[84.83,349.37],[101.9,234.17],[153.1,190.08],[340.83,168.74],[531.41,151.68],[571.23,168.74],[576.92,201.46],[557.01,227.06],[525.72,241.28]]],"tunnels":[],"platforms":[[401.0666666666667,709.6888888888888],[237.51111111111112,320]],"balls":[[7,3,3,6,5,5,5,6,6,4,4,4,6,3,3,5,5,4,4,4,4,5,3,7,7,5,5,6,6,5,5,7,6,6,6,7,3,3,3,3,5,5,3,6,6,7,7,7,7,6,4,4,6,6,6,6,7,7,5,4,3,3,5,5,7,3,3,3,7,7,7,3,5,5,5,7,7,5,5,5,7,4,7,7,4,5,5,5,6,6,5,4,4,6,7,6,6,6,5,5,3,6,6,6,6,7,7,3,3,3,3,6,5,7,7,6,6,3,3,7,4,4,4,7,7,7,4,6,6,6,3,3,4,4,3,7,7,7,3,3,3,7,7,5,5,7,7,7,7,5,4,4,5,5,5,5,4,6,6,5,3,3,3,6,5,4,3,3,4,4,7,7,3,5,5,5,5,4,4,3,3,3,4,6,6,5,4,4,4,3,6,4,6,6,6,4,4,7,3,3,3,6,5,3,3,5,5,3,4,4,4,4,3,3,4,5,7,6,6,7,7,6,4,4,4,6,5,5,6,6,6,3,4,4,3,3,7,6,6,7,7,7,4,5,5,5,4,4,4,7,7,7,3,4,4]],"coinPlaces":[[499.9377224199289,926.9750889679716],[54.67081850533809,613.8078291814948],[587.6245551601424,485.1245551601424]]},{"tension":0.3,"resolution":10,"paths":[[[565.54,93.37],[563.2,429.01],[475.94,429.01],[458.88,155.94],[372.12,140.3],[355.06,178.7],[394.88,366.93],[374.97,407.68],[292.48,399.14],[239.86,148.83],[187.23,134.61],[154.52,161.63],[127.08,197.19]],[[565.54,870.68],[559.86,528.57],[475.94,528.57],[458.88,814.43],[373.54,831.5],[355.06,793.1],[394.88,589.72],[374.97,552.74],[292.48,561.28],[241.28,814.43],[211.41,845.72],[173.01,840.03],[137.46,805.9]]],"tunnels":[],"platforms":[[110.93333333333334,486.9333333333334]],"balls":[[4,4,4,3,3,3,3,5,5,5,6,6,6,6,4,4,3,3,4,7,7,7,4,4,4,4,7,5,5,5,6,6,3,3,4,7,7,7,4,4,4,5,5,3,3,3,5,6,6,7,7,4,4,7,7,7,7,6,6,6,7,4,4,4,4,7,3,3,3,7,7,7,5,5,6,6,3,5,5,5,5,3,3,3,6,4,4,5,7,7,7,7,5,5,6,7,7,6,6,6,6,3,4,4,3,3,3,7,7,7,3,5,5,5,5,4,4,4,5,7,7,6,6,6,7,7,5,5,5,6,6,5,5,3,3,6,6,6,3,3,5,5,4,4,7,7,3,3,3,3,6,6,4,4,4,5,5,5,4,6,6,6,3,3,6],[6,3,3,6,6,6,4,5,5,5,4,4,4,6,6,3,3,3,3,7,7,4,4,5,5,3,3,6,6,6,3,3,5,5,6,6,5,5,5,7,7,6,6,6,7,7,5,4,4,4,5,5,5,5,3,7,7,7,3,3,3,4,4,3,6,6,6,6,7,7,6,5,5,7,7,7,7,5,4,4,6,3,3,3,5,5,5,5,3,6,6,5,5,7,7,7,3,3,3,7,4,4,4,4,7,6,6,6,7,7,7,7,4,4,7,7,6,6,5,3,3,3,5,5,4,4,4,7,7,7,4,3,3,6,6,5,5,5,7,4,4,4,4,7,7,7,4,3,3,4,4,6,6,6,6,5,5,5,3,3,3,3,4,4,4]],"coinPlaces":[[296.0943060498221,872.3131672597865],[296.0943060498221,195.87188612099646]]},{"tension":0.5,"resolution":10,"paths":[[[618.67,160.21],[446.08,157.37],[264.03,154.52],[130.34,160.21],[69.19,202.88],[60.66,283.94],[60.66,416.21],[60.66,542.79],[60.66,652.8],[64.92,778.88],[101.9,835.77],[190.08,849.99],[335.14,854.26],[474.52,854.26],[566.97,837.19],[584.03,770.34],[534.26,636.66],[460.3,485.9],[383.5,353.63],[289.63,242.7],[138.88,241.28],[121.81,343.68],[123.73,465.07],[126.58,591.64],[126.08,707.77],[153.1,777.46],[318.08,788.83],[468.83,783.14],[500.12,734.79],[441.81,596.83],[373.54,475.94],[283.94,380.66]]],"tunnels":[],"platforms":[[271.64444444444445,611.5555555555555]],"balls":[[7,4,4,7,7,7,4,6,6,3,3,3,6,6,0,5,5,5,6,7,4,4,7,7,4,6,5,5,6,3,5,5,5,3,3,5,0,6,6,6,0,0,7,3,3,7,7,3,4,7,7,7,4,4,7,5,6,3,4,4,4,3,3,4,0,6,6,0,0,0,4,4,0,3,7,5,5,5,7,7,5,4,6,3,3,3,6,6,3,3,3,6,0,0,5,5,0,7,7,4,6,6,6,3,4,4,3,3,5,6,5,5,6,6,6,5,0,0,0,7,5,5,7,7,7,3,4,4,4,3,3,7,6,6,6,7,7,3,3,3,6,0,7,7,7,0,0,3,0,0,5,5,0,0,0,5,4,4,4,7,6,6,0,4,4,4,0,0,6,3,5,5,5,4,4,5,0,0,0,4,3,3,6,6,6,3,4,0,5,5,5,0,0,5,7,3,3,3,5,5,4,7,7,4,4,4,5,7,7,7,0,6,6,0,0,0]],"coinPlaces":[[47.83807829181495,174.23487544483987],[140.08007117437728,934.9466192170819],[506.770462633452,936.0854092526691]]},{"tension":0.5,"resolution":10,"paths":[[[606.79,743.32],[434.7,791.68],[296.74,798.79],[184.39,764.66],[90.52,687.86],[53.54,535.68],[53.54,340.83],[83.41,231.32],[184.39,167.32],[315.23,151.68],[448.92,167.32],[549.9,231.32],[584.03,339.41],[585.46,537.1],[557.01,660.83],[470.26,723.41],[359.32,746.17],[234.17,724.83],[141.72,652.3],[104.74,524.3],[104.74,349.37],[140.3,258.34],[246.97,207.14],[397.72,214.26],[491.59,262.61],[531.41,356.48],[531.41,522.88],[498.7,629.54],[396.3,677.9],[278.26,675.06],[187.23,611.06],[157.37,474.52],[168.74,329.46],[262.61,265.46],[393.46,273.99],[465.99,330.88],[475.94,420.48],[448.92,491.59],[441.81,588.3],[520.03,761.81],[487.32,881.28],[333.72,862.79],[204.3,859.94]]],"tunnels":[[0,380,3.121717104085582,400,1.5934056158907015]],"platforms":[[301.5111111111111,456.53333333333336]],"balls":[[4,3,3,4,4,4,3,7,7,0,3,3,0,0,0,7,6,6,5,4,3,3,7,7,6,6,7,4,4,4,5,5,4,0,0,0,6,6,0,4,4,6,5,3,3,3,6,6,3,3,7,5,7,7,7,5,5,7,7,6,0,0,0,5,5,0,6,6,6,0,4,3,3,3,4,7,7,7,5,5,6,6,5,4,3,5,5,3,7,4,4,7,7,7,6,3,4,4,4,3,3,4,4,6,0,5,5,5,0,0,5,4,7,7,7,6,6,7,5,5,5,6,0,0,0,3,3,0,6,6,6,7,7,6,5,0,0,5,5,5,0,3,3,7,6,4,4,6,6,3,5,5,5,6,7,7,6,6,6,4,0,0,4,4,4,0,0,3,6,4,4,7,5,5,3,4,4,3,3,3,5,4,0,5,5,0,0,5,3,7,7,6,6,6,7,0,0,4,4,7,6,3,3,0,7,7,3,5,0,0,7,5,5,7,7,5,0,6,6,0,0,4,3,3,3,4,4,3]],"coinPlaces":[[54.670818505338076,774.3772241992883],[53.532028469750905,184.48398576512457],[571.6814946619216,184.48398576512454]]},{"tension":0.3,"resolution":10,"paths":[[[621.01,150.26],[461.72,150.26],[315.23,150.26],[130.34,153.1],[88.1,198.73],[84.83,296.74],[84.83,414.79],[83.27,547.05],[84.83,680.74],[100.48,784.01],[211.41,790.26],[323.77,790.26],[461.72,790.26],[521.46,747.59],[525.72,568.89],[521.46,414.79],[469.98,358.59]],[[22.26,231.32],[147.91,231.32],[258.84,231.32],[403.41,231.32],[564.12,246.96],[579.77,404.83],[579.77,578.84],[575.5,805.9],[507.23,865.63],[315.23,865.63],[219.94,865.63],[164.62,840.61],[163.06,717.72],[163.06,575.5],[163.06,460.3],[204.3,404.83]]],"tunnels":[[0,30,4.666334194909222,50,0.00037250220953355395],[1,100,-1.5635089687472536,120,3.140773242078197]],"platforms":[[354.1333333333334,564.6222222222223]],"balls":[[3,7,7,7,7,3,3,0,5,5,5,0,0,3,3,3,4,5,5,5,5,4,4,4,5,6,6,6,6,5,5,5,4,4,6,6,4,4,0,7,7,0,0,0,0,7,4,6,6,6,4,4,4,4,6,7,3,3,3,0,0,7,7,7,0,0,0,3,6,6,6,3,3,3,3,5,6,6,7,5,5,7,7,7,7,5,3,3,3,0,5,5,0,0,0,3,6,6,5,5,5,6,4,4,4,5,7,7,7,6,3,3,6,6,6,6,4,0,0,0,0,4,4,0,6,6,6,7,7,5,5,5,5,7,7,4,4,4,7,3,3,3,3,6,0,0,5,5,0,0,0,4,7,7,7,3,3,4,4,4,4,3],[3,4,4,4,4,3,3,7,7,7,4,0,0,0,5,5,0,0,6,3,3,3,3,7,4,4,4,7,7,5,5,5,5,7,7,6,6,6,0,4,4,0,0,0,0,4,6,6,6,6,3,3,6,7,7,7,5,4,4,4,6,5,5,5,6,6,3,0,0,0,5,5,0,3,3,3,5,7,7,7,7,5,5,7,6,6,5,3,3,3,3,6,6,6,3,0,0,0,7,7,7,0,0,3,3,3,7,6,4,4,4,4,6,6,6,4,7,0,0,0,0,7,7,0,4,4,6,6,4,4,5,5,5,6,6,6,6,5,4,4,4,5,5,5,5,4,3,3,3,0,0,5,5,5,0,3,3,7,7,7,7,3]],"coinPlaces":[[48.97686832740214,843.8434163701069],[159.43950177935943,933.8078291814948]]},{"tension":0.5,"resolution":10,"paths":[[[27.02,108.09],[72.03,144.57],[64.92,222.79],[66.34,282.52],[100.48,316.65],[155.95,310.97],[242.7,255.5],[335.15,197.19],[426.17,148.83],[473.09,140.29],[493.01,170.17],[470.25,208.57],[380.65,271.14],[289.63,330.88],[181.55,411.95],[89.1,517.19],[63.5,618.17],[113.28,697.81],[209.98,720.57],[312.39,689.27],[427.59,612.49],[528.57,532.83],[571.24,537.09],[569.81,581.19],[493.02,657.98],[396.8,728.18],[306.69,773.2],[216.18,796.44],[148.84,814.43],[150.75,864.71],[227.56,874.67],[339.91,860.44],[442.31,829.16]]],"tunnels":[],"platforms":[[352.71111111111117,486.4]],"balls":[[4,0,7,7,0,0,0,7,3,4,4,4,3,3,3,4,6,7,7,7,3,5,5,5,3,3,5,7,6,6,5,5,6,7,7,7,4,4,7,3,3,3,0,0,3,6,6,6,7,5,4,4,5,5,5,5,4,0,6,6,0,0,0,6,3,4,4,4,6,6,6,4,6,5,3,3,5,5,6,6,6,6,4,4,5,7,0,0,7,7,7,0,4,3,3,3,4,4,4,3,5,5,5,6,3,3,3,6,6,3,4,0,0,0,0,6,6,0,5,7,7,7,5,5,5,7,6,6,6,3,3,3,6,4,5,5,5,4,4,7,0,0,7,7,0,4,4,4,5,0,0,0,7,7,0,5,7,7,7,7,6,6,3,6,6,6,3,5,3,3,5,5,0,6,6,6,0,0,4,7,7,4,4,5,5,6,5,5,5,7,6,0,0,4,4,4,0,3,3,0,0,0,3,3,6,5,4,7,7,0,0,0,7,4,4,4,4,7,7,7,0,3,3,3,3,5,5,3]],"coinPlaces":[[232.32206405693955,191.3167259786477],[60.36476868327402,439.5729537366549],[77.44661921708185,816.5124555160144]]},{"tension":0.5,"resolution":10,"paths":[[[132.27,931.56],[126.58,833.42],[102.4,753.78],[68.27,659.91],[54.04,517.69],[54.04,395.38],[54.04,268.8],[62.08,190.08],[89.1,175.86],[114.7,190.08],[118.97,268.3],[118.97,395.38],[118.97,517.69],[136.03,653.72],[163.06,736.21],[219.94,815.86],[315.73,861.87],[419.06,858.52],[508.66,813.01],[566.97,731.94],[585.46,636.66],[589.72,512.92],[588.3,417.63],[579.77,303.86],[542.79,218.52],[451.77,165.9],[330.88,161.63],[239.86,200.03],[191.5,268.3],[178.7,342.26],[177.28,450.34],[184.39,559.86],[203.38,658.49],[249.81,749.01],[355.06,790.26],[461.72,746.17],[512.92,655.14],[525.72,517.19],[518.61,377.81],[494.43,278.26],[441.81,231.32],[376.39,251.23]]],"tunnels":[],"platforms":[[355.55555555555554,506.31111111111113]],"balls":[[7,6,6,6,4,4,4,6,7,5,5,7,7,7,3,4,0,0,4,4,3,3,3,3,6,6,4,3,3,0,0,0,6,6,0,7,6,6,7,7,7,6,3,3,0,5,6,6,5,5,6,3,3,4,6,6,0,4,4,0,0,0,7,5,5,5,7,7,7,7,5,5,3,3,3,5,6,5,0,0,5,5,5,4,6,6,0,4,4,4,5,7,3,3,3,6,7,7,7,6,3,3,6,6,6,6,4,7,7,4,4,4,0,0,3,3,3,0,5,5,5,5,7,7,5,5,3,6,6,5,7,7,4,0,4,4,0,0,0,5,4,4,3,6,3,0,0,5,6,6,6,5,0,3,3,6,4,4,7,0,7,5,5,5,7,0,5,5,0,0,0,6,4,4,4,4,3,3,4,0,0,7,7,7,0,0,3,5,5,5,7,7,3,6,6,6,3,3,5,7,7,3,5,5,4,4,4,5,6,6,6,4,7,4,4,4,3,4,5,5,5,4,4,5,3,3,3,7,0,0,0,4,4,0,6,7,7,7,6,4,6,6,6,4,5,5,0,3,3,3,0,0,3,7,7,0,0,0,0,7,3,7,7,3]],"coinPlaces":[[192.46441281138794,926.9750889679717],[498.7989323843417,928.113879003559],[589.9021352313168,182.2064056939502]]},{"tension":0.5,"resolution":10,"paths":[[[55.97,860.44],[55.97,738.13],[55.97,514.84],[55.97,340.83],[66.34,214.26],[137.46,158.79],[319.5,144.57],[446.08,163.06],[483.06,224.21],[491.59,370.7],[497.28,541.37],[475.94,677.9],[365.01,710.61],[264.03,730.52],[198.61,790.26]],[[582.61,861.37],[582.61,753.28],[582.61,615.32],[581.19,468.41],[561.28,315.23],[444.66,283.94],[367.86,205.72],[224.21,201.46],[145.99,239.86],[130.34,346.52],[130.34,477.37],[134.61,593.99],[150.26,692.12],[205.72,777.46],[279.68,821.54],[343.68,848.57],[407.68,871.32],[451.77,868.48],[471.1,837.19]]],"tunnels":[[0,80,2.6647096612781294,90,-0.05536590881483727],[1,120,2.949091779850751,140,-1.1677799467425816]],"platforms":[[323.1555555555557,424.62222222222215]],"balls":[[6,6,7,7,7,7,6,6,0,0,4,3,3,4,4,4,4,7,7,7,5,5,5,7,7,3,3,6,6,6,3,3,0,0,0,7,7,4,5,5,5,5,4,4,7,3,3,6,5,5,0,6,6,0,0,0,5,3,4,4,4,0,3,3,3,5,0,0,0,5,5,0,0,3,7,6,6,6,3,3,3,6,0,5,5,5,0,0,5,7,7,4,4,4,7,3,7,7,7,5,3,3,3,3,4,6,5,5,6,6,6,6,5,4,4,0,0,4,4,4,7,7,7,5,5,4,4,4,5,5,5,0,0,0,0,4,3,6,6,6,3,3,3,6,7,7,7,4,7,5,5,5,3,4,4,3,3,3,4,4,7,0,6,6,0,0,0,6,7,7,6,6,6,0],[0,6,6,6,7,7,6,0,0,0,6,6,0,7,4,4,3,3,3,4,4,3,5,5,5,7,4,7,7,7,6,3,3,3,6,6,6,3,4,0,0,0,0,5,5,5,4,4,4,5,5,7,7,7,4,4,4,0,0,4,4,5,6,6,6,6,5,5,6,4,3,3,3,3,5,7,7,7,3,7,4,4,4,7,7,5,0,0,5,5,5,0,6,3,3,3,6,6,6,7,3,0,0,5,5,0,0,0,5,3,3,3,0,4,4,4,3,5,0,0,0,6,6,0,5,5,6,3,3,7,4,4,5,5,5,5,4,7,7,0,0,0,3,3,6,6,6,3,3,7,7,5,5,5,7,7,7,4,4,4,4,3,3,4,0,0,6,6,7,7,7,7,6,6]],"coinPlaces":[[584.2081850533808,260.78291814946624],[45.560498220640575,174.23487544483987]]},{"tension":0.5,"resolution":10,"paths":[[[20.46,417.9],[52.12,318.08],[110.43,231.32],[198.61,171.59],[318.08,151.68],[450.34,173.01],[534.26,214.26],[564.12,265.46],[547.06,308.12],[494.43,318.08],[421.9,301.01],[318.08,288.21],[215.68,323.77],[138.88,399.14],[87.68,508.66],[74.88,628.12],[89.1,713.46],[130.34,788.83],[194.34,845.72],[282.52,869.9],[403.41,868.48],[511.5,835.77],[571.23,781.72],[579.59,715.48],[538.52,682.17],[485.9,700.66],[430.43,754.7],[345.1,788.83],[256.92,778.88],[190.08,726.26],[158.79,622.43],[182.97,495.86],[255.5,400.57],[370.7,373.54],[477.37,406.26],[522.88,454.61],[527.14,497.28]]],"tunnels":[],"platforms":[[356.9777777777778,577.4222222222222]],"balls":[[6,4,4,4,6,6,6,4,5,0,0,0,7,7,0,7,5,5,5,7,7,5,3,3,3,6,6,3,7,4,5,5,3,4,4,3,3,3,4,6,0,0,5,5,5,0,6,6,5,3,7,7,7,3,3,4,7,7,4,4,4,5,5,3,3,7,4,4,0,0,0,0,4,7,7,7,3,6,6,5,0,0,0,5,5,0,3,3,3,3,5,7,4,6,6,4,4,4,4,6,6,6,4,7,0,0,7,7,7,0,5,3,3,3,6,5,5,6,6,4,3,7,7,7,0,3,3,0,0,4,4,4,0,6,5,5,6,6,6,5,5,5,6,0,0,0,6,4,4,7,7,7,7,4,4,7,3,0,0,0,3,3,3,0,6,6,3,5,5,5,5,6,7,7,6,6,6,7,5,3,3,5,5,5,7,0,0,4,4,0,6,6,6,6,3,3,6,3,5,5,5,4,4,7,6,6,6,7,7,6,5,4,4,4,0,5,5,0,0,0,5,3,3,3,0,0,3,7,7,7,3,3,7,7,4,4,4,0,0,4]],"coinPlaces":[[62.6423487544484,849.5373665480428],[588.7633451957296,219.7864768683274],[137.80249110320284,161.7081850533808]]},{"tension":0.4,"resolution":10,"paths":[[[66.84,864.71],[96.21,743.32],[147.41,575.5],[154.52,447.5],[173.01,325.19],[221.06,254.42],[289.82,223.2],[358.15,223.2],[421.48,254.42],[462.26,325.19],[479.08,440.99],[481.06,611.34],[462.92,718.58],[397.65,775.19],[288.18,767.5],[145.13,694.1],[72.03,591.99],[59.81,433.28],[81.99,311.27],[136.61,222.79],[197.58,179.92],[316.95,151.39],[423.86,169.03],[509.61,217.51],[553.03,286.26],[555.01,387.23],[558.43,475.94],[559.86,619.59],[557.01,771.77],[538.52,828.66],[490.17,872.74],[420.48,878.43],[252.66,842.88]]],"tunnels":[[0,10,0.24461764416311116,20,3.2197500456802355],[0,190,0.6137973989946464,240,-0.044470015393381246]],"platforms":[[331.3777777777778,510.57777777777767]],"balls":[[6,7,7,7,7,5,5,7,6,6,0,0,6,6,0,4,4,3,3,3,3,4,4,3,6,6,6,5,5,5,6,3,7,7,3,3,7,0,0,6,6,6,0,0,3,4,5,5,5,5,4,4,4,5,3,3,6,7,7,7,5,5,5,7,6,6,0,5,5,0,0,0,6,7,7,7,3,3,4,4,4,3,7,6,6,6,4,4,7,0,0,5,5,5,7,7,4,7,7,4,4,4,6,6,0,0,4,3,3,3,4,7,3,3,3,6,4,0,0,0,0,3,3,0,7,4,4,4,7,7,7,6,0,0,6,6,6,0,5,5,3,3,3,5,0,0,0,6,4,4,0,7,7,5,4,6,6,7,0,0,0,4,4,0,5,5,6,3,3,3,4,4,3,0,5,3,5,4,0,0,0,5,7,7,5,5,5,0,3,3,4,4,4,4,3,7,7,7,5,5,6,6,7,3,3,0,0,0,7,7,0,5,3,3,3,5,5,5,3,6,6,6,6,5,4,4,7,7,4,6,6,5,5,7,7,7,5,4,6,6,6,0,0,6,4,4,4,3,5,5,3,3]],"coinPlaces":[[184.49288256227766,169.6797153024911],[480.5782918149467,170.81850533807832],[50.11565836298932,717.437722419929]]},{"tension":0.5,"resolution":10,"paths":[[[241.99,913.49],[241.99,729.47],[252.74,615.99],[323.34,557.71],[427.7,557.71],[493.7,611.38],[509.04,714.13],[515.18,804.61],[542.81,829.15],[568.9,804.61],[571.97,715.67],[559.69,602.18],[495.23,522.44],[373.98,496.37],[251.2,523.97],[188.28,602.18],[179.07,715.67],[176.5,843.45],[143.77,876.69],[108.47,843.45],[100.79,715.67],[99.26,660.46]],[[415.42,99.18],[410.82,254.07],[390.87,336.88],[331.01,385.95],[203.62,385.95],[137.63,333.81],[120.21,257.14],[154.51,212.66],[160.65,178.92],[145.3,146.72],[110,134.45],[73.17,145.19],[53.22,183.53],[54.75,254.07],[74.7,339.95],[129.96,413.56],[200.03,444.66],[268.59,450.86],[335.62,442.69],[401.61,413.56],[450.72,347.62],[466.07,252.54],[473.74,172.79],[518.25,139.05],[568.9,160.52],[573.5,232.6],[539.74,283.21],[538.21,373.69]]],"tunnels":[],"platforms":[[381.36630908796093,733.7894213702521],[282.2855315747402,221.9689030883919]],"balls":[[6,3,3,6,6,6,0,0,6,4,4,0,0,4,4,4,4,5,7,7,7,0,5,5,5,0,0,0,3,3,4,4,4,3,0,0,0,0,4,4,0,6,6,6,5,5,3,3,3,5,5,5,6,6,7,7,7,7,6,6,7,3,3,3,3,4,6,6,6,4,4,4,5,5,5,4,7,7,7,3,3,3,0,0,0,5,5,0,0,6,6,6,6,0,0,0,7,7,4,4,4,4,7,7,7,3,3,4,5,6,6,6,5,5,3,3,3,5,5,5,5,3,0,0,7,7,0,0,0,7,4,4,3,3,4,4,4,3,6,5,5,7,6,6,6,6,7,7,7,7,0,6,6,0,0,0,0,7,7,3,3,3,3,7,7,4,4,5,5,5,4,4,4,7,7,7,5,6,6,5,5,5,5,3,3,3],[3,3,3,5,5,5,5,6,6,5,7,7,7,4,4,4,5,5,5,4,4,7,7,3,3,3,3,7,7,0,0,0,0,6,6,0,7,7,7,7,6,6,6,6,7,5,5,6,3,4,4,4,3,3,4,4,7,0,0,0,7,7,0,0,3,5,5,5,5,3,3,3,5,5,6,6,6,5,4,3,3,7,7,7,4,4,4,4,7,7,0,0,0,6,6,6,6,0,0,5,5,0,0,0,3,3,3,7,7,7,4,5,5,5,4,4,4,6,6,6,4,3,3,3,3,7,6,6,7,7,7,7,6,6,5,5,5,3,3,3,5,5,6,6,6,0,4,4,0,0,0,0,3,4,4,4,3,3,0,0,0,5,5,5,0,7,7,7,5,4,4,4,4,0,0,4,4,6,0,0,6,6,6,3,3,6]],"coinPlaces":[[585.346975088968,551.1743772241994],[61.5035587188612,498.7900355871887],[46.69928825622776,826.7615658362989]]},{"tension":0.5,"resolution":10,"paths":[[[168.74,926.79],[94.79,817.28],[63.5,689.28],[57.81,487.32],[63.5,289.63],[117.54,191.5],[229.9,154.52],[392.03,148.83],[529.99,167.32],[564.12,194.34],[552.74,231.32],[501.54,241.28],[363.59,244.12],[232.74,255.5],[147.41,320.92],[137.46,481.63],[238.43,682.17],[328.03,749.01],[443.23,754.7],[538.52,733.37],[559.86,776.03],[500.12,835.77],[389.69,864.71],[254.08,852.83],[165.9,797.37],[154.52,675.06],[175.86,576.92],[215.68,495.86],[227.06,389.19],[278.26,343.68],[370.7,336.57],[470.26,337.99]]],"tunnels":[[0,250,0.0180950027331932,270,3.220712201065787]],"platforms":[[420.9777777777778,577.4222222222222]],"balls":[[7,7,7,3,4,4,4,3,3,4,7,7,0,6,6,0,0,0,6,5,5,5,6,6,5,5,5,7,5,3,3,3,0,0,3,4,4,0,7,7,7,4,5,5,5,3,3,5,6,6,6,6,5,6,3,7,0,0,0,5,5,0,3,7,3,3,7,7,7,7,6,5,5,5,6,6,6,5,5,7,7,0,3,3,0,0,7,4,0,0,0,4,4,4,0,5,7,3,3,3,7,3,6,3,3,3,6,6,6,3,0,5,5,0,0,0,4,7,7,7,4,4,4,7,4,5,5,5,6,4,4,6,6,6,5,0,7,7,6,6,7,7,6,0,0,4,3,3,4,4,3,7,0,0,0,4,5,5,5,5,4,4,5,6,6,6,0,0,6,7,7,3,3,3,3,4,4,0,0,3,3,3,0,5,6,6,5,5,6,6,4,4,4,7,7,7,0,4,4,4,0,0,4,5,5,7,7,4,3,3,5,5,4,4,5,6,6,6,3,7,0,0,3,3,0,0,0,0,7,7,6,4,4,6,6,4,4,4,4,6,6,7,7,7,6,3,5,5,3,3,3,5]],"coinPlaces":[[54.67081850533809,178.79003558718864],[498.79893238434164,926.9750889679716]]},{"tension":0.4,"resolution":10,"paths":[[[586.88,852.83],[586.88,683.59],[586.88,453.19],[585.46,291.06],[576.92,170.17],[504.39,150.26],[221.37,150.26],[73.46,155.94],[73.46,204.3],[217.1,205.72],[426.17,207.14],[520.03,217.1],[531.41,291.06],[532.83,456.03],[528.57,585.46],[480.21,603.94],[404.83,539.94],[318.08,460.3],[208.57,350.79],[126.08,271.14],[93.37,275.41],[90.52,309.54],[164.48,386.34],[276.83,500.12],[380.66,598.26],[510.08,713.46],[500.12,766.08],[389.19,770.34],[265.46,770.34],[124.66,760.39],[110.43,670.79],[106.17,475.94],[54.54,475.94],[52.12,673.63],[57.81,784.57],[116.12,851.41],[221.37,858.52],[332.3,861.37],[423.32,868.48]]],"tunnels":[],"platforms":[[234.66666666666669,641.4222222222221],[401.0666666666666,334.22222222222223]],"balls":[[5,6,7,4,6,6,6,4,4,4,4,6,4,0,0,0,5,5,0,7,7,7,5,6,6,7,4,4,3,6,6,7,3,3,4,7,7,6,4,5,6,6,5,5,4,4,4,5,3,3,4,4,3,6,6,5,5,5,7,5,5,5,7,6,0,0,3,3,0,5,7,7,5,4,3,3,3,4,4,7,3,6,6,7,0,3,3,0,0,0,5,7,7,7,5,5,6,3,3,6,6,6,6,7,4,7,7,4,4,3,3,3,0,4,4,0,0,7,5,5,0,0,0,5,4,7,7,4,4,4,3,3,3,3,4,6,6,6,0,3,3,3,0,0,6,0,4,4,3,7,7,7,6,3,5,3,4,4,4,3,3,3,4,6,5,5,3,7,7,5,5,0,0,3,6,0,0,0,3,3,0,7,5,5,5,5,4,4,5,7,7,5,5,5,7,7,7,5,7,4,4,4,6,4,3,3,4,0,0,6,6,6,0,3,6,3,3,0,7,7,0,0,5,5,0,6,6,6,7,7,6,6,3,0,0,0,0,5,5,0,4,4,7,0,0,7,7,7,7,0,6,6,4,5,5,5,3,6,6,3,0,0,6,5]],"coinPlaces":[[48.976868327402066,285.8362989323843]]},{"tension":0.5,"resolution":10,"paths":[[[19.91,147.91],[157.37,164.48],[217.1,241.28],[180.12,417.63],[259.77,578.34],[453.19,683.59],[417.63,780.3],[241.28,854.26],[157.37,865.63],[96.21,821.54],[73.46,721.07],[69.19,569.81],[73.46,372.12],[86.26,328.03]],[[617.24,147.91],[488.74,163.06],[424.74,238.43],[458.88,417.63],[373.54,554.17],[315.23,586.88],[229.9,636.66],[191.5,685.01],[191.5,734.79],[231.32,784.57],[357.9,851.41],[467.91,874.67],[541.37,837.19],[561.28,721.07],[568.39,569.81],[565.54,370.7],[554.17,325.19]]],"tunnels":[[1,40,3.840865027231255,60,0.6961864098085523],[0,60,3.863965958267853,70,1.3530971196568682]],"platforms":[[310.0444444444445,378.31111111111113]],"balls":[[0,6,6,6,6,0,0,0,3,4,4,4,3,3,3,7,5,5,5,5,7,7,5,3,3,3,0,7,7,7,0,0,0,0,7,7,7,4,5,5,4,4,4,5,6,7,7,7,7,6,6,6,0,0,4,4,0,0,0,6,3,3,3,6,6,6,3,4,5,5,5,5,3,3,5,5,6,4,4,4,6,6,6,7,7,7,4,4,6,6,3,0,0,0,3,3,3,3,0,5,5,5,0,0,0,6,4,4,4,4,7,7,7,6,6,7,0,0,5,5,5,6,6,6,5,3,3,3,5,5,0,0,0,7,7,7,0,0,7,5,5,5,3,3,4,4,4,4,3,7,7,3,3,3,3,4,4,6,6,6,6,4,5,5,5,4,4,4,6,6,6,7,7,7,7,3,3,7,0,0,0,0,7,7,0,5,3,3,3,5,5,5,4,4,4,6,6,4],[4,6,6,4,4,4,5,5,5,3,3,3,5,0,7,7,0,0,0,0,7,3,3,7,7,7,7,6,6,6,4,4,4,5,5,5,4,6,6,6,6,4,4,3,3,3,3,7,7,3,4,4,4,4,3,3,5,5,5,7,0,0,7,7,7,0,0,0,5,5,3,3,3,5,6,6,6,5,5,5,0,0,7,6,6,7,7,7,4,4,4,4,6,0,0,0,5,5,5,0,3,3,3,3,0,0,0,3,6,6,4,4,7,7,7,6,6,6,4,4,4,6,5,5,3,3,5,5,5,5,4,3,6,6,6,3,3,3,6,0,0,0,4,4,0,0,6,6,6,7,7,7,7,6,5,4,4,4,5,5,4,7,7,7,0,0,0,0,7,7,7,0,3,3,3,5,7,7,5,5,5,5,7,3,3,3,4,4,4,3,0,0,0,6,6,6,6,0]],"coinPlaces":[[589.9021352313168,243.7010676156584],[50.11565836298932,244.83985765124558],[313.1761565836299,750.4626334519573]]},{"tension":0.5,"resolution":10,"paths":[[[611.56,102.4],[427.59,190.08],[262.61,303.86],[127.5,434.7],[81.99,547.06],[94.79,659.41],[178.7,736.21],[309.54,734.79],[431.86,652.3],[524.3,524.3],[576.92,380.66],[564.12,271.14],[464.57,259.77],[339.41,323.77],[224.21,420.48],[148.83,542.79],[174.43,659.41],[293.9,673.63],[438.97,535.68],[510.08,389.19],[458.88,357.9],[343.68,465.99],[235.59,575.5],[137.03,630.97],[73.46,685.01],[72.03,760.39],[130.34,841.46],[191.5,869.9],[271.14,845.72]]],"tunnels":[[0,220,3.954083544463526,250,-0.5490910747619901]],"platforms":[[126.57777777777781,200.53333333333333],[516.2666666666667,814.9333333333333]],"balls":[[6,3,3,4,4,4,4,3,6,6,6,7,5,0,0,0,5,5,0,7,7,7,0,5,4,3,6,6,7,3,3,6,6,4,5,5,5,4,4,5,7,7,7,7,4,0,0,0,3,3,0,7,6,6,6,7,7,5,5,3,7,7,3,0,0,0,4,4,0,0,6,3,3,3,3,6,6,6,4,7,3,3,5,6,6,6,7,7,7,6,0,0,0,0,5,5,0,3,4,4,4,7,7,5,4,4,7,7,4,5,5,5,3,7,7,4,4,4,7,6,6,6,0,3,3,0,0,6,4,4,4,5,3,5,5,5,5,3,3,3,5,7,0,0,0,7,6,4,4,4,6,6,6,6,4,6,5,5,3,5,4,4,4,7,0,0,7,7,7,0,4,3,3,6,6,4,4,6,3,3,3,4,4,0,5,5,5,0,0,6,4,3,3,3,5,5,5,3,5,5,6,3,3,3,6,6,5,0,0,4,4,0,7,7,7,0,0,7,5,5,5,4,7,7,0,0,0,6,6,3,3,3,6,6,0,7,7,7,5,5]],"coinPlaces":[]},{"tension":0.5,"resolution":10,"paths":[[[449.55,96.94],[543.06,157.31],[560.6,281.51],[560.6,433.47],[560.6,596.16],[557.67,731.55],[528.45,838.22],[410.09,865.98],[218.68,865.98],[95.94,830.92],[68.18,700.87],[82.79,529.91],[169,382.33],[221.6,303.43],[256.67,228.91],[244.98,145.62],[204.07,109.09],[131.01,109.09],[88.63,157.31],[85.71,262.51],[100.32,376.49],[150,529.91],[158.77,613.2],[164.61,700.87],[204.07,785.62],[391.1,791.46],[451.01,731.55],[459.77,596.16],[459.77,433.47],[458.31,323.88]]],"tunnels":[[0,150,-0.19048556299196284,180,0.08195835538640495],[0,200,2.9668622764680386,220,-0.027809575542312226]],"platforms":[[314.15525114155247,496.8036529680365]],"balls":[[6,6,4,4,3,7,7,7,4,4,4,5,5,5,4,7,7,7,0,6,6,0,0,0,7,3,3,4,4,3,6,6,6,5,5,6,3,5,5,5,5,3,4,4,4,3,5,5,6,7,7,0,6,6,0,0,0,7,5,4,3,3,4,4,3,5,5,4,4,3,3,5,6,3,3,3,7,4,4,0,0,6,6,6,0,0,4,6,3,4,4,5,6,6,4,0,3,3,3,0,4,5,5,4,3,7,7,4,4,0,0,3,3,0,0,4,5,6,7,7,3,3,3,7,5,6,6,5,5,0,4,4,4,5,0,0,7,7,7,7,0,5,5,7,7,3,3,3,7,7,7,3,4,4,3,3,6,6,6,4,3,3,7,7,7,3,4,4,4,7,0,0,0,0,3,3,0,7,6,6,7,5,6,3,3,3,3,6,6,7,7,6,6,6,6,0,0,3,5,5,0,0,6,6,6,0,0,7,4,4,5,7,7,6,6,4,4,5,5,5,4,7,7,4,7,5,5,5,7,7,0,5,5,5,6,0,0,6,6,5,5,7,7,7,0,3,3,3,7,0,0,0,5,5,0,3,3,4,5,7,7,6,6,4,4,6,0,0,7,7,6,6,3,5,5,3,3,6,6,6,3,3,7,0,5,5,0,0,0,5,6,6,5,7,7,5,4,4,4,4,0,5,5,3,3,0,0,0,6,4,4,4,6,0,0,6,5,5,5,6,4,7,7,3,3,7,4,4,0,0]],"coinPlaces":[[593.3185053380784,851.8149466192172],[52.39323843416373,466.90391459074743],[167.41103202846975,193.59430604982208]]},{"tension":0.5,"resolution":10,"paths":[[[567.47,863.29],[567.47,689.78],[567.47,489.24],[567.47,295.82],[545.63,208.57],[458.88,160.21],[320.92,148.83],[195.77,163.06],[118.97,191.5],[77.72,251.23],[67.77,352.21],[144.57,457.46],[301.01,512.92],[421.9,549.9],[502.97,606.79],[511.5,700.66],[461.72,760.39],[458.88,824.39]],[[64.92,858.52],[64.92,695.47],[64.92,493.01],[76.3,326.61],[182.97,272.57],[273.99,215.68],[426.17,218.52],[488.74,269.72],[497.28,387.77],[471.68,495.86],[350.79,534.26],[200.03,582.61],[164.48,625.28],[158.79,687.86],[158.79,760.39],[161.63,825.81]]],"tunnels":[[0,80,4.316294766149959,110,-1.1435598366756379],[1,90,3.4945109943030728,120,0.09794581949220538]],"platforms":[[338.4888888888889,685.5111111111112],[331.5333333333333,356.9777777777778]],"balls":[[4,4,4,0,0,7,7,7,7,5,5,5,6,6,6,6,5,0,3,3,3,3,4,4,3,3,0,0,0,4,7,7,7,4,4,4,4,7,5,5,5,6,6,3,3,4,7,7,7,4,4,4,0,0,5,5,3,3,3,5,0,0,0,7,7,4,4,6,6,6,4,4,4,4,7,3,3,3,7,7,7,3,3,0,0,0,0,5,5,0,6,6,3,5,5,5,5,3,3,3,6,4,4,5,7,7,7,7,0,0,0,5,5,0,7,7,6,6,6,6,7,3,4,4,3,3,3,6,7,7,7,3,5,5,5,5,4,4,4,5,0,0,0,7,7,6,6,6,7,7,4,5,5,5,6,6,5,5,6,0,0,3,3,0,6,6,6,3,3,0,5,5,0,0,0,0,6,4,4,6,6,6,3,7,7,3,3,3,3,7,4,0,0,6,6,0,0,4,4,4,5,5,5,3,3,5,6,6,6,0,0,4,5,5,4,4,0,0,0,7,7,7,6,6,7,7,6,3,3,3,6,6,5,5,5,7,4,4,4,3],[4,4,4,0,0,7,7,7,7,5,5,5,6,6,6,6,5,0,3,3,3,3,4,4,3,3,0,0,0,4,7,7,7,4,4,4,4,7,5,5,5,6,6,3,3,4,7,7,7,4,4,4,0,0,5,5,3,3,3,5,0,0,0,7,7,4,4,6,6,6,4,4,4,4,7,3,3,3,7,7,7,3,3,0,0,0,0,5,5,0,6,6,3,5,5,5,5,3,3,3,6,4,4,5,7,7,7,7,0,0,0,5,5,0,7,7,6,6,6,6,7,3,4,4,3,3,3,6,7,7,7,3,5,5,5,5,4,4,4,5,0,0,0,7,7,6,6,6,7,7,4,5,5,5,6,6,5,5,6,0,0,3,3,0,6,6,6,3,3,0,5,5,0,0,0,0,6,4,4,6,6,6,3,7,7,3,3,3,3,7,4,0,0,6,6,0,0,4,4,4,5,5,5,3,3,5,6,6,6,0,0,4,5,5,4,4,0,0,0,7,7,7,6,6,7,7,6,3,3,3,6,6,5,5,5,7,4,4,4,3]],"coinPlaces":[[591.040925266904,174.23487544483984],[58.08718861209965,231.17437722419933]]},{"tension":0.5,"resolution":10,"paths":[[[67.21,102.28],[110.55,157.31],[99.06,225.63],[101.9,293.9],[130.34,337.99],[185.81,350.79],[242.06,323.88],[312.19,233.29],[385.25,173.38],[463.14,145.99],[528.57,175.86],[555.25,245.48],[541.37,310.97],[483.15,356.03],[415.94,383.79],[360.41,427.63],[339.41,481.63],[360.41,539.94],[421.9,584.03],[490.17,619.59],[533.33,657.99],[561.28,721.99],[537.1,794.52],[463.14,835.77],[396.3,824.39],[318.08,767.5],[242.06,673.63],[185.81,642.34],[124.66,650.88],[90.52,697.81],[96.21,756.12],[133.19,797.37]]],"tunnels":[],"platforms":[[186.31111111111113,490.6666666666667]],"balls":[[4,4,3,3,3,3,6,6,4,3,5,4,4,6,6,7,5,5,7,7,7,3,3,5,4,3,3,4,4,4,3,7,7,5,5,5,7,7,7,7,3,3,6,6,7,6,4,4,5,5,4,3,6,7,7,6,6,7,5,4,4,3,3,4,7,3,4,6,6,6,4,4,4,4,7,3,5,5,3,3,5,6,6,3,3,3,7,4,4,6,6,6,4,5,6,3,4,4,4,6,6,4,5,3,3,5,5,4,4,6,7,7,4,5,6,3,3,3,7,6,6,7,4,5,5,4,3,3,3,7,6,4,4,6,5,7,7,7,5,5,3,7,7,7,3,6,6,6,4,7,7,4,4,4,5,3,6,7,7,5,5,5,7,6,6,6,6,3,7,6,4,4,5,5,5,5,7,7,5,4,5,5,5,7,7,5,3,6,3,7,7,7,3,3,3,5,5,3,3,4,5,7,7,5,5,4,6,6,6,4,4,6,7,6,6,7,7,5,5,3,6,6,7,3,3,6,7,5,5,6,5,4,3,7,7,3,4,4,3,3,4,4,4,5,6,6,5,6,5,5,5,3,3,6,7]],"coinPlaces":[]},{"tension":0.5,"resolution":10,"paths":[[[221.87,284.44],[335.64,409.6]]],"tunnels":[],"platforms":[],"balls":[[3,6,3,3,3,5,6,7,7,5,7,5,5,6,5,7,3,3,5,6,7,7,6,5,5,7,3,3,3,3,7,5,6,6,3,7,7,6,5,5,5,3,6,6,6,6,7,5,5,3,6,7,7,5,7,3,3,5,6,6,7,3,5,5,5,5,3,7,7,5,3,3,7,6,5,5,7,3,3,3,5,3,6,6,3,6,7,7,7,6,6,7,3,5,5,6,6,6,3,6,6,6,5,7,7,7,6,5,3,3,5,6,6,7,3,3,6,7,7,7,7,6,3,5,5,5,7,3]],"coinPlaces":[]},{"tension":0.5,"resolution":10,"paths":[[[19.91,147.91],[157.37,164.48],[217.1,241.28],[180.12,417.63],[259.77,578.34],[453.19,683.59],[417.63,780.3],[241.28,854.26],[157.37,865.63],[96.21,821.54],[73.46,721.07],[69.19,569.81],[73.46,372.12],[86.26,328.03]],[[617.24,147.91],[488.74,163.06],[424.74,238.43],[458.88,417.63],[373.54,554.17],[315.23,586.88],[229.9,636.66],[191.5,685.01],[191.5,734.79],[231.32,784.57],[357.9,851.41],[467.91,874.67],[541.37,837.19],[561.28,721.07],[568.39,569.81],[565.54,370.7],[554.17,325.19]]],"tunnels":[[1,40,3.840865027231255,60,0.6961864098085523],[0,60,3.863965958267853,70,1.3530971196568682]],"platforms":[[310.0444444444445,378.31111111111113]],"balls":[[6,6,6,6,7,7,3,5,3,7,3,3,6,6,6,7,3,3,5,5,5,3,6,6,3,3,7,5,5,5,3,3,3,5,6,5,7,7,3,3,3,5,7,7,6,3,3,7,3,5,7,6,6,5,5,5,3,5,7,6,3,5,5,5,7,3,6,5,5,3,7,7,7,6,5,5,3,3,6,5,7,3,3,5],[5,5,5,7,3,3,3,3,5,6,6,5,7,7,3,3,3,6,5,5,5,7,3,3,6,3,3,3,7,6,6,7,7,6,6,6,7,7,6,6,3,3,7,7,3,3,7,5,5,7,7,5,5,5,6,6,6,6,3,3,3,6,7,7,7,3,6,6,6,5,7,7,7,6,6,6,7,7,7,7,5,3,3,5,5,3,7,7,7,3,5,5,5,7,7,6,6,6,3,3,3,3,5,5,5,5,6,6,6,5,7,7,7,6,6,3,3,3,5,5,5,3,6,6,6,6,5,3,3,3,5,5,7,7,7,7,6,5,5,3,3,3,3,6,7,7,7,3,6,6,6,7,5,5,5,5,6,6,6,7,7,7,6,6,5,5,5,3,3,3,5,6,6,6,6,3,7,7,7,5,5,6,3,3,3,7,5,5,5,5,6,6,3,3,5,5,5,3,7,7,7,7,6,5,5,7,3,3]],"coinPlaces":[]},null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],"settings":{"LEVEL_SPEED":[80,80,80,65,85,85,65,85,85,65,85,85,65,90,90,60,90,95,65,90,95,65,90,95,65,90,95,65,90,95,60,95,100,65,95,100,65,95,100,65,100,105,70,90,105,70,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80,80],"CHAIN_QUICK_FILL_IN_PERCENTAGE_VALUES":[0.35,0.4,0.4,0.4,0.5,0.45,0.4,0.5,0.5,0.4,0.5,0.5,0.4,0.5,0.5,0.4,0.5,0.5,0.4,0.5,0.5,0.4,0.5,0.5,0.4,0.5,0.5,0.4,0.5,0.5,0.4,0.55,0.55,0.45,0.55,0.55,0.45,0.55,0.55,0.45,0.55,0.55,0.45,0.55,0.55,0.45,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35,0.35],"FREE_BALL_SPEED":750,"FREE_BALL_INSERTION_SPEED":450,"FREE_BALL_INSERTION_SPEED_MULTIPLIER":6.5,"PATH_ACCELERATION":10,"PATH_EXPOTENTIAL_ACCELERATION":1.06,"GAP_COLLAPSING_MAX_SPEED":700,"GAP_COLLAPSING_ACCELERATION_MULTIPLIER":1.16,"GAP_COLLAPSING_HIT_SLOWDOWN_FACTOR":0.75,"GAP_COLLAPSING_STARTING_SPEED":-30,"BALL_EXPLOSION_DELAY":0,"ZOOMER_COOLDOWN":400,"ZOOMER_RECOIL":8,"ZOOMER_RECOIL_DURATION":100,"ZOOMER_MAX_SAME_COLOR_BALLS_SEQUENCE":2,"CHAIN_START_SPEED":650,"CHAIN_LOSE_SPEED":650,"CHAIN_LOSE_ACCELERATION_MULTIPLIER":1,"CHAIN_QUICK_FILL_IN_BREAKING_ABSOLUTE_DISTANCE":150,"SLOWDOWN_POINT_BALLS_COUNT":15,"SLOWDOWN_POINT_SPEED_MULTIPLIER":0.5,"SLOWDOWN_POWERUP_SPEED_MULTIPLIER":0.1,"FIREBALL_SPEED_MULTIPLIER":0.9,"REWIND_SPEED":-400,"SLOWDOWN_POWERUP_DURATION":4000,"REWIND_POWERUP_DURATION":3000,"LASER_POWERUP_DURATION":12000,"LASER_FREE_BALL_SPEED_MULTIPLIER":1.75,"LIGHTING_DELAY_BETWEEN_STRIKES":25,"LIGHTING_MIN_TARGETS":3,"LIGHTING_MAX_TARGETS":6,"BOMB_EXPLOSION_RADIUS":185,"BOMB_EXPLOSION_DELAY":50,"PATH_SPEED_AFTER_DESTROYING_TAIL":0.1,"FIREBALL_ANGLE":18,"PATH_ARROW_STEP":20,"PATH_ARROW_BASE_DELAY":150,"PATH_ARROW_DURATION":1100,"PATH_FINISHED_BONUS_DELAY":65,"PATH_FINISHED_BONUS_SCORE":10,"PATH_FINISHED_BONUS_STEP":60,"SLOWDOWN_APPEARING_CHANCE":0.1,"REWIND_APPEARING_CHANCE":0.06,"BOMB_APPEARING_CHANCE":0.1,"LIGHTING_APPEARING_CHANCE":0.06,"LASER_APPEARING_CHANCE":0.12,"FIREBALL_APPEARING_CHANCE":0.08,"CHANCE_APPEARING_MULTIPLIER":1.05,"POWERUP_LIFETIME":20000,"POWERUP_COOLDOWN":10000,"POWERUP_TIMER":15000,"POWERUP_TIMER_DEVIATION":0.15,"MAX_ACTIVE_POWERUPS":4,"ZOOMER_PRIORITY_DISTANCE":200,"ZOOMER_PRIORITY_BALLS_LIMIT":5,"ZOOMER_PRIORITY_PROBABILITY":0.7,"COIN_CHANCE":0.7,"COIN_LIFETIME":20000,"COIN_TIMER":25000,"COIN_TIMER_DEVIATION":0.1,"MAX_ACTIVE_COINS":1,"INSTANTLY_ADD_ALL_COINS":false,"BALL_SCORE":10,"COIN_SCORE":400,"TIME_BONUS_POINTS_PER_SECOND_PENALTY":5,"PATH_GENERATOR_USE_SINGLE_COLOR":false,"CHAIN_QUICK_FILL_IN_PERCENTAGE":0.35,"BALL_REVERSE_SPEED_MULTIPLIER":6,"GAP_COLLAPSING_ACCELERATION_FACTOR":0.5,"CHAIN_QUICK_FILL_IN_BREAKING_DISTANCE":0.1,"LIGHTING_COLLAPSE_GAPS_SPEED_MULTIPLIER":1,"LIGHTING_STRIKE_COLLAPSE_DELAY":1000,"COMBO_SCORE":100,"GAP_SCORE":1000,"PATH_ARROW_SPEED":1600,"CHAIN_START_SPEED_MULTIPLIER":7,"CHAIN_SLOWDOWN_FACTOR":0.955,"CHAIN_SPEEDUP_FACTOR":1.055,"REWIND_SPEED_MULTIPLIER":5,"CHAIN_LOSE_SPEED_MULTIPLIER":8,"BALL_SPEED":75,"SLOWDOWN_APPEARING_CHANCES":[0.18,0.18,0.2,0.22,0.24,0.18,0.2,0.22,0.24,0.26],"REWIND_APPEARING_CHANCES":[0.18,0.18,0.2,0.22,0.24,0.18,0.2,0.22,0.24,0.26],"BOMB_APPEARING_CHANCES":[0.2,0.2,0.22,0.24,0.26,0.2,0.22,0.24,0.26,0.28],"LIGHTING_APPEARING_CHANCES":[0.16,0.16,0.18,0.2,0.22,0.16,0.18,0.2,0.22,0.24],"LASER_APPEARING_CHANCES":[0.22,0.22,0.24,0.26,0.28,0.22,0.24,0.26,0.28,0.3],"FIREBALL_APPEARING_CHANCES":[0.14,0.14,0.16,0.18,0.2,0.14,0.16,0.18,0.2,0.22],"LIGHTING_POWERUP_DURATION":3000}}');
            this.levels = this.savedLevels["levels"];
        };
        LevelStorage.prototype.getLevel = function (level) {
            if (level < 1 || level > src.Settings.TOTAL_LEVELS) {
                return null;
            }
            return this.levels[level];
        };
        return LevelStorage;
    }());
    src.LevelStorage = LevelStorage;
})(src || (src = {}));
var src;
(function (src) {
    var BackgroundManager = (function (_super) {
        __extends(BackgroundManager, _super);
        function BackgroundManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.level = level;
            _this.createGraphics();
            return _this;
        }
        /**
         * PRIVATE METHODS
         */
        BackgroundManager.prototype.createGraphics = function () {
            this.background = this.add(this.game.make.image(14, 75, 'background1'));
            this.background.anchor.setTo(0);
        };
        /**
         * DESTROY METHOD
         */
        BackgroundManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.background = null;
        };
        return BackgroundManager;
    }(Phaser.Group));
    src.BackgroundManager = BackgroundManager;
})(src || (src = {}));
var src;
(function (src) {
    var BallManager = (function (_super) {
        __extends(BallManager, _super);
        function BallManager(path) {
            var _this = _super.call(this, src.App.instance) || this;
            _this.path = path;
            _this.level = _this.path.pathManager.level;
            _this.ballFactory = new src.BallFactory(_this);
            _this.contactResolver = new src.BallContactResolver(_this);
            _this.ballRenderer = _this.add(new src.BallRenderer(_this));
            return _this;
        }
        BallManager.prototype.initQueue = function (balls) {
            this.balls = [];
            this.ballFactory.createQueue(balls);
        };
        BallManager.prototype.update = function () {
            _super.prototype.update.call(this);
            this.removeDeadBalls();
            this.contactResolver.update();
            this.removeDeadBalls();
            this.ballFactory.update();
            this.updateContacts();
            this.ballRenderer.render();
        };
        BallManager.prototype.getFirstBall = function () {
            if (this.balls && this.balls.length > 0) {
                for (var i = 0; i < this.balls.length; i++) {
                    if (this.balls[i] && this.balls[i].isAlive) {
                        return this.balls[i];
                    }
                }
            }
            return null;
        };
        BallManager.prototype.getLastBall = function () {
            if (this.balls && this.balls.length > 0) {
                for (var i = this.balls.length - 1; i > -1; i--) {
                    if (this.balls[i] && this.balls[i].isAlive) {
                        return this.balls[i];
                    }
                }
            }
            return null;
        };
        BallManager.prototype.getLastMovingBall = function () {
            var ball = this.getFirstBall();
            while (ball && ball.isAlive && ball.getNext() && ball.getNext().isAlive && ball.isTouching(ball.getNext(), false)) {
                ball = ball.getNext();
            }
            return ball;
        };
        BallManager.prototype.getAliveBallsCount = function () {
            return this.balls.reduce(function (counter, ball) {
                return ball.isAlive ? counter + 1 : counter;
            }, 0);
        };
        BallManager.prototype.hasAliveBalls = function () {
            return this.getAliveBallsCount() > 0;
        };
        BallManager.prototype.getFutureBallsCount = function () {
            return this.ballFactory.ballsQueue.length;
        };
        BallManager.prototype.insertBall = function (path, targetBall, color, x, y, startPosition) {
            var pathPoint = targetBall.pathPoint;
            if (pathPoint == path.getStartPoint()) {
                this.ballFactory.insertBallAfter(path, targetBall, color, x, y, startPosition);
                return;
            }
            if (pathPoint == path.getEndPoint()) {
                this.ballFactory.insertBallBefore(path, targetBall, color, x, y, startPosition);
                return;
            }
            var pathPointProgress = targetBall.segmentProgress / pathPoint.pathLength;
            var previousPosition = (pathPointProgress <= 0.5) ? path.getConcretePosition(pathPoint.chainIndex) : path.getConcretePosition(pathPoint.chainIndex + pathPointProgress - (1 - pathPointProgress));
            var nextPosition = (pathPointProgress <= 0.5) ? path.getConcretePosition(pathPoint.chainIndex + 2 * pathPointProgress) : path.getConcretePosition(pathPoint.chainIndex + 1);
            if (previousPosition && nextPosition) {
                if (Phaser.Math.distance(x, y, previousPosition.x, previousPosition.y) < Phaser.Math.distance(x, y, nextPosition.x, nextPosition.y) && !this.level.powerupManager.hasActivePowerup(src.PowerupType.REWIND)) {
                    this.ballFactory.insertBallBefore(path, targetBall, color, x, y, startPosition);
                }
                else {
                    this.ballFactory.insertBallAfter(path, targetBall, color, x, y, startPosition);
                }
            }
        };
        BallManager.prototype.getGapBonusesCount = function (ball) {
            var gaps = 0;
            var ballTrail = new Phaser.Line(ball.freeBallStartPosition.x, ball.freeBallStartPosition.y, ball.position.x, ball.position.y);
            var currentPathSegment = new Phaser.Line(0, 0, 1, 1);
            var intersections = [];
            for (var i = 0; i < this.path.pathPoints.length - 1; i++) {
                currentPathSegment.setTo(this.path.pathPoints[i].x, this.path.pathPoints[i].y, this.path.pathPoints[i + 1].x, this.path.pathPoints[i + 1].y);
                var intersectionPoint = ballTrail.intersects(currentPathSegment, true);
                if (intersectionPoint) {
                    var relativePosition = this.path.pathPoints[i].chainIndex + Phaser.Math.distance(this.path.pathPoints[i].x, this.path.pathPoints[i].y, intersectionPoint.x, intersectionPoint.y) / (this.path.pathPoints[i].pathLength == 0 ? 1 : this.path.pathPoints[i].pathLength);
                    intersections.push(relativePosition);
                }
            }
            //remove waste results
            for (var j = intersections.length - 1; j > 0; j--) {
                if (!this.hasBallsBetween(intersections[j - 1], intersections[j])) {
                    intersections.splice(j - 1, 1);
                }
            }
            //calculate gaps
            if (intersections.length == 1) {
                gaps += (this.hasBallsBetween(0, intersections[0]) && this.hasBallsBetween(intersections[0], this.path.getTotalLength())) ? 1 : 0;
            }
            else {
                for (var k = 0; k < intersections.length; k++) {
                    if (k == 0) {
                        gaps += (this.hasBallsBetween(0, intersections[k]) && this.hasBallsBetween(intersections[k], intersections[k + 1])) ? 1 : 0;
                    }
                    else if (k == intersections.length - 1) {
                        gaps += (this.hasBallsBetween(intersections[k - 1], intersections[k]) && this.hasBallsBetween(intersections[k], this.path.getTotalLength())) ? 1 : 0;
                    }
                    else {
                        gaps += (this.hasBallsBetween(intersections[k - 1], intersections[k]) && this.hasBallsBetween(intersections[k], intersections[k + 1])) ? 1 : 0;
                    }
                }
            }
            return gaps;
        };
        BallManager.prototype.getOncomingBalls = function () {
            var oncomingBalls = [];
            for (var i = 0; i < this.balls.length; i++) {
                if (this.balls[i].isAlive && !this.balls[i].onTheWay) {
                    oncomingBalls.push(this.balls[i]);
                }
            }
            return oncomingBalls;
        };
        BallManager.prototype.propagateImpulse = function (epicenter, impulse) {
            var prevBall = epicenter;
            while (prevBall && prevBall.getPrev() && (prevBall.isTouching(prevBall.getPrev(), false) || Phaser.Math.distance(prevBall.x, prevBall.y, epicenter.x, epicenter.y) <= src.Settings.game.BOMB_EXPLOSION_RADIUS)) {
                prevBall.backwardSpeed = -impulse;
                prevBall = prevBall.getPrev();
            }
            var nextBall = epicenter;
            while (nextBall && nextBall.getNext() && (nextBall.isTouching(nextBall.getNext(), false) || Phaser.Math.distance(nextBall.x, nextBall.y, epicenter.x, epicenter.y) <= src.Settings.game.BOMB_EXPLOSION_RADIUS)) {
                nextBall.backwardSpeed = impulse;
                nextBall = nextBall.getNext();
            }
        };
        BallManager.prototype.getSequences = function () {
            var sequences = [];
            var currentSequence = new src.BallSequence(this);
            var ball = this.getFirstBall();
            while (ball) {
                currentSequence.push(ball);
                var next = ball.getNext();
                if (next && !next.onTheWay && next.getNext() && next.getNext().getAbsolutePosition() - ball.getAbsolutePosition() <= 2 * src.Settings.BALL_DIAMETER) {
                    currentSequence.push(next);
                    currentSequence.push(next.getNext());
                    ball = next.getNext();
                    continue;
                }
                if (!next || !ball.isTouching(next, false)) {
                    sequences.push(currentSequence);
                    currentSequence = new src.BallSequence(this);
                }
                ball = next;
            }
            return sequences;
        };
        /**
         * DISPATCHERS
         */
        BallManager.prototype.dispatchAddingBallToTheChain = function (ball) {
            if (ball && ball.isAlive) {
                var subChain = this.getSameColoredNeighborsChain(ball);
                if (subChain.length >= 3) {
                    this.destroySubchain(subChain);
                }
                else {
                    ball.gapBonus = 0;
                }
            }
        };
        BallManager.prototype.dispatchGapDestroyingBetween = function (ballA, ballB) {
            var _this = this;
            if (ballA && ballB && ballA.isAlive && ballB.isAlive && ballA.onTheWay && ballB.onTheWay) {
                if (ballA.color == ballB.color) {
                    this.game.time.events.add(src.Settings.GAP_DISAPPEARING_REACTION_DELAY, function (ball) {
                        _this.dispatchAddingBallToTheChain(ball);
                    }, this, ballA);
                }
            }
        };
        BallManager.prototype.dispatchBallExploding = function (ball) {
            src.StatsManager.instance.addBalls(1);
            if (this.getAliveBallsCount() == 1 && this.ballFactory.ballsQueue.length == 0) {
                this.path.isCleared = true;
                this.path.pathFinalizer.setStartposition(ball.getRelativePosition());
                this.path.pathCleared();
            }
        };
        /**
         * PRIVATE METHODS
         */
        BallManager.prototype.removeDeadBalls = function () {
            for (var i = this.balls.length - 1; i > -1; i--) {
                if (!this.balls[i].isAlive) {
                    this.balls.splice(i, 1);
                }
            }
        };
        BallManager.prototype.getSameColoredNeighborsChain = function (ball) {
            var chain = [ball];
            var prevBall = ball.getPrev();
            while (prevBall && prevBall.color == ball.color && prevBall.onTheWay && prevBall.getNext() && prevBall.isTouching(prevBall.getNext(), false)) {
                chain.unshift(prevBall);
                prevBall = prevBall.getPrev();
            }
            var nextBall = ball.getNext();
            while (nextBall && nextBall.color == ball.color && nextBall.onTheWay && nextBall.getPrev() && nextBall.isTouching(nextBall.getPrev(), false)) {
                chain.push(nextBall);
                nextBall = nextBall.getNext();
            }
            return chain;
        };
        BallManager.prototype.destroySubchain = function (subChain) {
            var prevBall = subChain[0].getPrev();
            var nextBall = subChain[subChain.length - 1].getNext();
            //slowdown speed
            if (subChain.indexOf(this.getFirstBall()) != -1) {
                this.path.speedManager.setChainSpeed(src.Settings.game.PATH_SPEED_AFTER_DESTROYING_TAIL, true);
            }
            //resolve scores &  combos
            var prevScore = 0;
            var score = src.ScoreManager.instance.calculateScores(subChain.length);
            var currentComboMultiplier = 1;
            var comboSoundIndex = Phaser.ArrayUtils.getRandomItem(subChain).comboSoundIndex;
            var gapBonus = 0;
            for (var i = 0; i < subChain.length - 1; i++) {
                if (subChain[i].comboMultiplier > currentComboMultiplier && subChain[i].comboMultiplier == subChain[i + 1].comboMultiplier) {
                    currentComboMultiplier = subChain[i].comboMultiplier;
                    comboSoundIndex = subChain[i].comboSoundIndex;
                    prevScore += subChain[i].previousScore;
                }
                if (subChain[i].gapBonus > gapBonus) {
                    gapBonus = subChain[i].gapBonus;
                }
            }
            var gapBonusScore = gapBonus > 0 ? gapBonus * subChain.length * src.Settings.game.BALL_SCORE : 0;
            src.StatsManager.instance.addGapBonusScore(gapBonusScore);
            var comboBonusScore = prevScore + src.ScoreManager.instance.calculateScores(subChain.length) * (currentComboMultiplier - 1);
            src.StatsManager.instance.addComboBonusScore(comboBonusScore);
            //display scores
            var targetX = (subChain.length % 2 == 1) ? subChain[Math.floor(subChain.length / 2)].x : Phaser.Math.average(subChain[Math.floor(subChain.length / 2)].x, subChain[Math.floor(subChain.length / 2) - 1].x);
            var targetY = (subChain.length % 2 == 1) ? subChain[Math.floor(subChain.length / 2)].y : Phaser.Math.average(subChain[Math.floor(subChain.length / 2)].y, subChain[Math.floor(subChain.length / 2) - 1].y);
            src.ScoreManager.instance.displayScores(score + comboBonusScore + gapBonusScore, true, subChain[0].color, targetX, targetY);
            //display gap bonus
            if (gapBonus > 0) {
                var gapBonusX = (subChain.length % 2 == 1) ? subChain[Math.floor(subChain.length / 2)].x : Phaser.Math.average(subChain[Math.floor(subChain.length / 2)].x, subChain[Math.floor(subChain.length / 2) - 1].x);
                var gapBonusY = (subChain.length % 2 == 1) ? subChain[Math.floor(subChain.length / 2)].y : Phaser.Math.average(subChain[Math.floor(subChain.length / 2)].y, subChain[Math.floor(subChain.length / 2) - 1].y);
                this.level.effectsManager.addGapBonus(gapBonusX, gapBonusY + 70, gapBonus, 350);
            }
            //display combo
            if (currentComboMultiplier >= 2) {
                var comboX = (subChain.length % 2 == 1) ? subChain[Math.floor(subChain.length / 2)].x : Phaser.Math.average(subChain[Math.floor(subChain.length / 2)].x, subChain[Math.floor(subChain.length / 2) - 1].x);
                var comboY = (subChain.length % 2 == 1) ? subChain[Math.floor(subChain.length / 2)].y : Phaser.Math.average(subChain[Math.floor(subChain.length / 2)].y, subChain[Math.floor(subChain.length / 2) - 1].y);
                this.level.effectsManager.addComboEffect(comboX, comboY, currentComboMultiplier, 10, comboSoundIndex);
            }
            //destroy balls
            for (var _i = 0, subChain_1 = subChain; _i < subChain_1.length; _i++) {
                var ball = subChain_1[_i];
                if (src.Settings.game.BALL_EXPLOSION_DELAY > 10) {
                    this.game.time.events.add(src.Settings.game.BALL_EXPLOSION_DELAY * subChain.indexOf(ball), function (ball) { return ball.explodeBall(); }, 0, ball);
                }
                else {
                    ball.explodeBall();
                }
            }
            //set combo multipliers
            if (prevBall && prevBall.isAlive && nextBall && nextBall.isAlive) {
                if (prevBall.color == nextBall.color && prevBall.comboMultiplier == nextBall.comboMultiplier) {
                    prevBall.previousScore = score + prevScore;
                    prevBall.comboMultiplier = currentComboMultiplier + 1;
                    nextBall.comboMultiplier = currentComboMultiplier + 1;
                    prevBall.comboSoundIndex = comboSoundIndex + 1;
                    nextBall.comboSoundIndex = comboSoundIndex + 1;
                }
            }
            //propagate reverse speed stop
            var nextBallInChain = nextBall;
            while (nextBallInChain) {
                nextBallInChain.backwardSpeed = 0;
                nextBallInChain = nextBallInChain.getNext();
            }
        };
        BallManager.prototype.updateContacts = function () {
            //mark balls that would have been destroyed
            for (var i = this.balls.length - 1; i > -1; i--) {
                this.balls[i].updateContacts();
            }
        };
        BallManager.prototype.hasBallsBetween = function (relativePositionA, relativePositionB) {
            if (relativePositionA <= relativePositionB) {
                for (var i = 0; i < this.balls.length; i++) {
                    if (this.balls[i].getRelativePosition() >= relativePositionA && this.balls[i].getRelativePosition() <= relativePositionB) {
                        return true;
                    }
                }
            }
            else {
                for (var i = this.balls.length - 1; i > -1; i--) {
                    if (this.balls[i].getRelativePosition() >= relativePositionB && this.balls[i].getRelativePosition() <= relativePositionA) {
                        return true;
                    }
                }
            }
            return false;
        };
        /**
         *  DESTROY METHOD
         */
        BallManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.ballsContainer = null;
            this.level = null;
            this.path = null;
            this.ballFactory.destroy();
            this.ballFactory = null;
            this.contactResolver.destroy();
            this.contactResolver = null;
            this.balls = null;
        };
        return BallManager;
    }(Phaser.Group));
    src.BallManager = BallManager;
})(src || (src = {}));
var src;
(function (src) {
    var CannonManager = (function (_super) {
        __extends(CannonManager, _super);
        function CannonManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.level = level;
            _this.pathManager = _this.level.pathManager;
            return _this;
        }
        CannonManager.prototype.buildAll = function () {
            this.platforms = [];
            this.destroyAllBalls();
            this.destroyAllPlatforms();
            this.addPlatforms(src.LevelManager.instance.cachedLevel.platforms);
            if (this.platforms.length > 1) {
                this.game.time.events.loop(Phaser.Timer.SECOND * src.Settings.PLATFORM_HIGHLIGHT_CHECKING_PERIOD, this.updateHighlightings, this);
            }
        };
        CannonManager.prototype.handleTap = function () {
            if (this.cannon.isReady) {
                var inputPosition = this.level.getInputPosition();
                for (var _i = 0, _a = this.platforms; _i < _a.length; _i++) {
                    var platform = _a[_i];
                    if (platform.handleTap(inputPosition)) {
                        this.cannon.jumpToPlatform(platform);
                        return;
                    }
                }
                if (this.cannon.isPointerOver(inputPosition)) {
                    this.cannon.swapBalls();
                }
                else {
                    this.cannon.shoot();
                }
            }
        };
        CannonManager.prototype.handleSwap = function () {
            if (this.cannon && this.cannon.isReady) {
                this.cannon.swapBalls();
            }
        };
        CannonManager.prototype.addPlatforms = function (coordinates) {
            for (var _i = 0, coordinates_1 = coordinates; _i < coordinates_1.length; _i++) {
                var coordPair = coordinates_1[_i];
                var platform = this.level.daemonManager.add(new src.Platform(this, coordPair[0], coordPair[1]));
                this.platforms.push(platform);
                if (!this.cannon) {
                    this.cannon = this.add(new src.Cannon(this, platform));
                }
            }
        };
        CannonManager.prototype.removePlatform = function (platform) {
            this.platforms.splice(this.platforms.indexOf(platform), 1);
            if (this.platforms.length > 0) {
                if (this.cannon) {
                    this.cannon.jumpToPlatform(this.platforms[0]);
                }
            }
            else {
                this.cannon.destroy();
                this.cannon = null;
            }
            platform.destroy();
        };
        CannonManager.prototype.getFirstColor = function () {
            var randomPath = Phaser.ArrayUtils.getRandomItem(this.level.pathManager.paths);
            if (randomPath) {
                if (randomPath.ballManager.balls.length > 0) {
                    return Phaser.ArrayUtils.getRandomItem(randomPath.ballManager.balls).color;
                }
                else if (randomPath.ballManager.ballFactory.ballsQueue.length > 0) {
                    return randomPath.ballManager.ballFactory.ballsQueue[randomPath.ballManager.ballFactory.ballsQueue.length - 1].color;
                }
            }
            return src.BallFactory.getRandomColor();
        };
        CannonManager.prototype.getNextColor = function (except) {
            var criticalColors = this.level.pathManager.getCriticalColors();
            if (criticalColors && criticalColors.length > 0) {
                return Phaser.ArrayUtils.getRandomItem(criticalColors);
            }
            var availableColors = this.level.pathManager.getOnScreenColorsArray(except);
            if (availableColors.length > 0) {
                return Phaser.ArrayUtils.getRandomItem(availableColors);
            }
            else {
                var futureColors = this.level.pathManager.getFutureColorsArray(except);
                if (futureColors.length > 0) {
                    return Phaser.ArrayUtils.getRandomItem(futureColors);
                }
                else {
                    if (except) {
                        var allColors = this.level.pathManager.getOnScreenColorsArray(null).concat(this.level.pathManager.getFutureColorsArray(null));
                        if (allColors.length > 0) {
                            return Phaser.ArrayUtils.getRandomItem(allColors);
                        }
                    }
                    return src.BallFactory.getRandomColor();
                }
            }
        };
        CannonManager.prototype.update = function () {
            if (this.level.gameStateManager.isPaused) {
                return;
            }
            _super.prototype.update.call(this);
            this.removeDeadBalls();
            this.resolveContacts();
            if (this.game.device.desktop || !this.cannon.isPointerOver(this.level.getInputPosition())) {
                this.cannon.rotateToPointer(this.level.getInputPosition());
            }
        };
        /**
         * PRIVATE METHODS
         */
        CannonManager.prototype.updateHighlightings = function () {
            var targetPlatform = null;
            var minAverageDistance = Number.MAX_VALUE;
            var _loop_1 = function (platform) {
                var distance = 0;
                var ballsCount = 0;
                for (var _i = 0, _a = this_1.level.pathManager.paths; _i < _a.length; _i++) {
                    var path = _a[_i];
                    distance += path.ballManager.balls.reduce(function (totalDistance, ball) { return totalDistance + Phaser.Math.distance(ball.x, ball.y, platform.x, platform.y); }, 0);
                    ballsCount += path.ballManager.balls.length;
                }
                if (ballsCount == 0) {
                    return { value: void 0 };
                }
                distance /= ballsCount;
                if (distance < minAverageDistance) {
                    minAverageDistance = distance;
                    targetPlatform = platform;
                }
            };
            var this_1 = this;
            for (var _i = 0, _a = this.platforms; _i < _a.length; _i++) {
                var platform = _a[_i];
                var state_1 = _loop_1(platform);
                if (typeof state_1 === "object")
                    return state_1.value;
            }
            if (targetPlatform && targetPlatform != this.cannon.platform) {
                targetPlatform.highlight();
            }
        };
        CannonManager.prototype.removeDeadBalls = function () {
            if (this.balls) {
                for (var i = this.balls.length - 1; i > -1; i--) {
                    if (!this.balls[i].isAlive) {
                        this.balls.splice(i, 1);
                    }
                }
            }
        };
        CannonManager.prototype.destroyAllBalls = function () {
            if (this.balls) {
                for (var _i = 0, _a = this.balls; _i < _a.length; _i++) {
                    var ball = _a[_i];
                    ball.destroy();
                }
            }
            this.balls = [];
        };
        CannonManager.prototype.destroyAllPlatforms = function () {
            if (this.platforms) {
                for (var i = this.platforms.length - 1; i > -1; i--) {
                    this.removePlatform(this.platforms[i]);
                }
            }
            this.platforms = [];
        };
        CannonManager.prototype.resolveContacts = function () {
            if (!this.balls) {
                return;
            }
            for (var i = this.balls.length - 1; i > -1; i--) {
                this.findCoinContact(this.balls[i]);
                if (this.balls[i].isAlive) {
                    this.findChainContact(this.balls[i]);
                }
            }
        };
        CannonManager.prototype.findCoinContact = function (ball) {
            for (var _i = 0, _a = this.level.coinManager.coins; _i < _a.length; _i++) {
                var coin = _a[_i];
                if (coin && coin.isAlive && coin.isTouching(ball)) {
                    coin.pickupCoin();
                    ball.killBall();
                }
            }
        };
        CannonManager.prototype.findChainContact = function (ball) {
            var touchingBall = null;
            var touchingBallDistance = Number.MAX_VALUE;
            var touchingBallTargetPosition;
            var trailLength = Phaser.Math.distance(ball.x, ball.y, ball.previousPosition.x, ball.previousPosition.y);
            for (var _i = 0, _a = this.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                var ballManager = path.ballManager;
                for (var _b = 0, _c = ballManager.balls; _b < _c.length; _b++) {
                    var chainedBall = _c[_b];
                    if (chainedBall.isAlive && !chainedBall.isUnderground && Phaser.Math.distance((ball.x + ball.previousPosition.x) / 2, (ball.y + ball.previousPosition.y) / 2, chainedBall.x, chainedBall.y) <= trailLength / 2 + src.Settings.BALL_DIAMETER) {
                        var distanceToTrail = src.AdvancedMath.CollisionDetector.distanceToSegment(chainedBall.position, ball.previousPosition, ball.position);
                        if (distanceToTrail <= src.Settings.BALL_DIAMETER) {
                            var contactPosition = src.AdvancedMath.CollisionDetector.getCollisionPoint(chainedBall.x, chainedBall.y, ball.previousPosition.x, ball.previousPosition.y, ball.x, ball.y);
                            var distanceToTrailStart = Phaser.Math.distance(contactPosition.x, contactPosition.y, ball.previousPosition.x, ball.previousPosition.y);
                            if (distanceToTrailStart < touchingBallDistance) {
                                if (ball instanceof src.FireBall && chainedBall.getRelativePosition() < 1) {
                                    //skip contact
                                }
                                else {
                                    touchingBall = chainedBall;
                                    touchingBallDistance = distanceToTrailStart;
                                    touchingBallTargetPosition = contactPosition;
                                }
                            }
                        }
                    }
                }
            }
            if (touchingBall) {
                ball.position.copyFrom(touchingBallTargetPosition);
                this.handleBallContact(ball, touchingBall);
            }
        };
        /**
         * Handles contact between freeBall and chained ball.
         * @returns {boolean} true if the freeBall is alive and able to continue flying, false if it has killed.
         */
        CannonManager.prototype.handleBallContact = function (freeBall, ball) {
            if (freeBall instanceof src.FireBall) {
                src.ScoreManager.instance.displayScores(src.ScoreManager.instance.calculateScores(1), true, ball.color, ball.x, ball.y, Phaser.Math.random(5, 150), true, true);
                ball.explodeBall();
                return true;
            }
            else {
                ball.ballManager.insertBall(ball.path, ball, freeBall.color, freeBall.x, freeBall.y, freeBall.startPosition.clone());
                freeBall.killBall();
                return false;
            }
        };
        /**
         *  DESTROY METHOD
         */
        CannonManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.pathManager = null;
        };
        return CannonManager;
    }(Phaser.Group));
    src.CannonManager = CannonManager;
})(src || (src = {}));
var src;
(function (src) {
    var CoinManager = (function (_super) {
        __extends(CoinManager, _super);
        function CoinManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.countdown = src.Settings.game.COIN_TIMER;
            _this.level = level;
            _this.coins = [];
            _this.coinPlaces = [];
            return _this;
        }
        CoinManager.prototype.buildCoins = function () {
            if (!src.LevelManager.instance.cachedLevel.coinPlaces) {
                src.LevelManager.instance.cachedLevel.coinPlaces = [];
            }
            for (var _i = 0, _a = src.LevelManager.instance.cachedLevel.coinPlaces; _i < _a.length; _i++) {
                var coinPosition = _a[_i];
                var coinPlace = new src.CoinPlace(coinPosition[0], coinPosition[1]);
                this.coinPlaces.push(coinPlace);
            }
            if (src.Settings.game.INSTANTLY_ADD_ALL_COINS) {
                for (var _b = 0, _c = this.coinPlaces; _b < _c.length; _b++) {
                    var coinPlace = _c[_b];
                    var coin = this.add(new src.Coin(this, coinPlace));
                    this.coins.push(coin);
                }
            }
        };
        CoinManager.prototype.hideAllCoins = function () {
            this.coins.forEach(function (coin) { return coin.destroy(); });
        };
        CoinManager.prototype.update = function () {
            if (this.level.gameStateManager.isPaused) {
                return;
            }
            _super.prototype.update.call(this);
            if (this.coinPlaces.length == 0) {
                return;
            }
            this.removeDeadCoins();
            this.countdown -= this.game.time.elapsedMS;
            if (this.countdown < 0) {
                this.addRandomCoin();
                this.countdown = src.Settings.game.COIN_TIMER * (1 + this.game.rnd.realInRange(-src.Settings.game.COIN_TIMER_DEVIATION, src.Settings.game.COIN_TIMER_DEVIATION));
            }
        };
        /**
         * PRIVATE METHODS
         */
        CoinManager.prototype.addRandomCoin = function () {
            var activeCoins = this.getCoinsCount();
            if (activeCoins >= src.Settings.game.MAX_ACTIVE_COINS || activeCoins > this.level.pathManager.getBallsCount() / 3) {
                return;
            }
            if (Math.random() > src.Settings.game.COIN_CHANCE || this.getFreeCoinPlacesCount() == 0) {
                return;
            }
            var coinPlace = this.getRandomEmptyCoinPlace();
            var coin = this.add(new src.Coin(this, coinPlace));
            this.coins.push(coin);
        };
        CoinManager.prototype.removeDeadCoins = function () {
            if (!this.coins) {
                return;
            }
            for (var i = this.coins.length - 1; i > -1; i--) {
                if (!this.coins[i].isAlive) {
                    this.coins.splice(i, 1);
                }
            }
        };
        CoinManager.prototype.getCoinsCount = function () {
            return this.coins.length;
        };
        CoinManager.prototype.getFreeCoinPlacesCount = function () {
            return this.coinPlaces.reduce(function (counter, currentValue) { return currentValue.coin ? counter : counter + 1; }, 0);
        };
        CoinManager.prototype.getRandomEmptyCoinPlace = function () {
            return Phaser.ArrayUtils.getRandomItem(this.coinPlaces.filter(function (coinPlace) { return coinPlace.coin == null; }));
        };
        /**
         *  DESTROY METHOD
         */
        CoinManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.coins = null;
            this.coinPlaces = null;
        };
        return CoinManager;
    }(Phaser.Group));
    src.CoinManager = CoinManager;
})(src || (src = {}));
var src;
(function (src) {
    var DaemonManager = (function (_super) {
        __extends(DaemonManager, _super);
        function DaemonManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.level = level;
            return _this;
        }
        DaemonManager.prototype.buildDaaemons = function () {
            this.daemons = [];
            for (var _i = 0, _a = this.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                var pathPoint = path.pathPoints[path.pathPoints.length - 2];
                var prevPathPoint = path.pathPoints[path.pathPoints.length - 3];
                var rotation = Phaser.Math.angleBetween(prevPathPoint.x, prevPathPoint.y, pathPoint.x, pathPoint.y) + Math.PI / 2;
                var daemon = this.add(new src.Daemon(this, path, pathPoint.x, pathPoint.y, rotation));
                this.daemons.push(daemon);
                path.daemon = daemon;
            }
        };
        DaemonManager.prototype.update = function () {
            if (!this.level.gameStateManager.isPaused) {
                _super.prototype.update.call(this);
            }
        };
        /**
         * PRIVATE METHODS
         */
        /**
         *  DESTROY METHOD
         */
        DaemonManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.daemons = null;
        };
        return DaemonManager;
    }(Phaser.Group));
    src.DaemonManager = DaemonManager;
})(src || (src = {}));
var src;
(function (src) {
    var EffectsManager = (function (_super) {
        __extends(EffectsManager, _super);
        function EffectsManager(level) {
            var _this = _super.call(this, level.game, null) || this;
            _this.level = level;
            _this.layerA = _this.add(_this.game.make.group(null));
            _this.layerB = _this.add(_this.game.make.group(null));
            _this.layerC = _this.add(_this.game.make.group(null));
            return _this;
        }
        EffectsManager.prototype.update = function () {
            if (!this.level.gameStateManager.isPaused) {
                _super.prototype.update.call(this);
            }
        };
        /**
         * PUBLIC METHODS
         */
        EffectsManager.prototype.addBallExplosion = function (container, color, x, y) {
            if (!(color in src.BallColor)) {
                console.log("EffectsManager::addBallExplosion - wrong color " + color);
                return;
            }
            var sprite = container.add(this.game.make.sprite(x, y, src.Settings.GAME_ATLAS));
            sprite.anchor.set(0.5);
            sprite.animations.add('ballExplosion' + color, Phaser.Animation.generateFrameNames('ballExplosion' + color, 0, 13, '', 4), 30, false);
            sprite.animations.play('ballExplosion' + color, 60, false, true);
            return sprite;
        };
        EffectsManager.prototype.addCoinExplosion = function (x, y) {
            this.addCoinsEffect(x, y);
            this.level.effectsManager.addCoinBonus(x, y - 10, 0);
        };
        EffectsManager.prototype.addBombExplosion = function (x, y) {
            var sprite = this.layerA.add(this.game.make.sprite(x, y, src.Settings.GAME_ATLAS));
            sprite.anchor.set(0.5);
            sprite.animations.add('bombExplosion', Phaser.Animation.generateFrameNames('bombExplosion', 0, 17, '', 4));
            sprite.animations.play('bombExplosion', 90, false, true);
        };
        /**
         * COMBO EFFECT
         */
        EffectsManager.prototype.addComboEffect = function (x, y, comboMultiplier, delay, soundIndex) {
            if (soundIndex === void 0) { soundIndex = 0; }
            for (var i = this.layerC.children.length - 1; i > -1; i--) {
                if (this.layerC.getChildAt(i) instanceof src.ComboEffect) {
                    this.layerC.removeChildAt(i);
                }
            }
            src.StatsManager.instance.addCombos(1);
            this.layerC.add(new src.ComboEffect(this, Phaser.Math.random(x - 50, x + 50), Phaser.Math.random(y + 30, y + 110), comboMultiplier, delay, soundIndex));
            this.level.powerupManager.dispatchComboAppearing(comboMultiplier);
        };
        /**
         * SCORES EFFECT
         */
        EffectsManager.prototype.addScoresEffect = function (x, y, scores, color, delay, targetScale, playPopSound) {
            var _this = this;
            this.layerB.add(new src.ScoresEffect(this, color, x, y, scores, delay, targetScale));
            if (playPopSound) {
                this.game.time.events.add(delay, function () { return _this.game.sound.play('pop', 1); });
            }
        };
        /**
         * COIN EFFECT
         */
        EffectsManager.prototype.addCoinBonus = function (x, y, delay) {
            this.layerC.add(new src.CoinBonus(this, x, y, delay));
            this.game.sound.play('coin_bonus', 0.8);
        };
        EffectsManager.prototype.addCoinsEffect = function (x, y) {
            var emitter = this.layerC.add(this.game.make.emitter(x, y - 35, 30));
            emitter.makeParticles(src.Settings.GAME_ATLAS, Phaser.Animation.generateFrameNames('coin', 0, 12, '', 4));
            emitter.gravity.setTo(0, 2000);
            emitter.width = 120;
            emitter.setXSpeed(-50, 50);
            emitter.setYSpeed(-400, -200);
            emitter.autoAlpha = true;
            emitter.setAlpha(1, 0, 500, Phaser.Easing.Sinusoidal.In);
            emitter.setScale(0.35, 0.2, 0.35, 0.2, 500);
            emitter.start(true, 400, null, src.App.instance.rnd.integerInRange(10, 15));
            this.game.time.events.add(500, function (emitter) {
                emitter.destroy(true);
            }, this, emitter);
        };
        /**
         * GAP BONUS EFFECT
         */
        EffectsManager.prototype.addGapBonus = function (x, y, multiplier, delay) {
            src.StatsManager.instance.addGaps(multiplier);
            this.layerC.add(new src.GapBonus(this, multiplier, x, y, delay));
            this.level.powerupManager.dispatchGapBonusAppearing(multiplier);
        };
        /**
         * DESTROY METHOD
         */
        EffectsManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
        };
        return EffectsManager;
    }(Phaser.Group));
    src.EffectsManager = EffectsManager;
})(src || (src = {}));
var src;
(function (src) {
    var ForegroundManager = (function (_super) {
        __extends(ForegroundManager, _super);
        function ForegroundManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.level = level;
            _this.createGraphics();
            return _this;
        }
        ForegroundManager.prototype.update = function () {
            _super.prototype.update.call(this);
            if (src.Settings.ENABLE_DEBUG_OUTPUT) {
                this.game.debug.text('' + this.game.time.fps || '--', 20, 14, "#70f0ff");
            }
        };
        /**
         * PRIVATE METHODS
         */
        ForegroundManager.prototype.createGraphics = function () {
            this.frameImage = this.add(this.game.make.image(-43, -73, 'frame'));
            this.frameImage.anchor.setTo(0);
        };
        /**
         * DESTROY METHOD
         */
        ForegroundManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.frameImage = null;
        };
        return ForegroundManager;
    }(Phaser.Group));
    src.ForegroundManager = ForegroundManager;
})(src || (src = {}));
var src;
(function (src) {
    var GameStateManager = (function (_super) {
        __extends(GameStateManager, _super);
        function GameStateManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this._isPaused = false;
            _this.isStarted = false;
            _this.isFinished = false;
            _this.isLost = false;
            _this.hasLosingPaths = false;
            _this.level = level;
            _this.isPaused = false;
            return _this;
        }
        GameStateManager.prototype.startInitialization = function () {
            this.level.pathManager.start();
        };
        GameStateManager.prototype.startBalls = function () {
            if (this.isStarted) {
                return;
            }
            this.level.pathManager.paths.forEach(function (path) { return path.start(); });
            this.level.cannonManager.cannon.start();
            this.isStarted = true;
        };
        GameStateManager.prototype.finishLevel = function () {
            if (!this.isFinished) {
                this.isFinished = true;
                this._isPaused = true;
                src.ScoreManager.instance.currentScore = src.StatsManager.instance.calculateReward();
                this.level.uiManager.scoresValue.text = '' + src.StatsManager.instance.calculateReward();
                if (this.level.pathManager) {
                    this.level.pathManager.pauseAll();
                }
                src.WindowManager.instance.showResults();
            }
        };
        GameStateManager.prototype.loseLevel = function () {
            if (!this.isLost) {
                this.isLost = true;
                this._isPaused = true;
                if (this.level.pathManager) {
                    this.level.pathManager.pauseAll();
                }
                this.level.cannonManager.cannon.destroyBalls();
                this.level.coinManager.hideAllCoins();
                src.WindowManager.instance.showDefeat();
            }
        };
        GameStateManager.prototype.pauseLevel = function () {
            this.isPaused = true;
            window.famobi_analytics.trackScreen("SCREEN_PAUSE");
            src.WindowManager.instance.showPause();
        };
        GameStateManager.prototype.resumeLevel = function () {
            this.isPaused = false;
            window.famobi_analytics.trackScreen("SCREEN_LEVEL");
        };
        /**
         * MAIN CYCLE
         */
        GameStateManager.prototype.update = function () {
            _super.prototype.update.call(this);
            this.updateGameState();
        };
        /**
         * CHECK FINISH
         */
        GameStateManager.prototype.updateGameState = function () {
            if (this.isPaused || this.isFinished || this.isLost) {
                return;
            }
            this.hasLosingPaths = this.level.pathManager.paths.reduce(function (status, currentPath) { return status || currentPath.hasEatenBalls; }, false);
            var defeat = this.level.pathManager.paths.reduce(function (status, currentPath) { return status && currentPath.isLost; }, true);
            if (defeat && !this.isLost) {
                this.loseLevel();
            }
            var victory = this.level.pathManager.paths.reduce(function (status, currentPath) { return status && currentPath.isFinished; }, true);
            if (victory && !this.isFinished) {
                this.finishLevel();
            }
        };
        Object.defineProperty(GameStateManager.prototype, "isPaused", {
            /**
             * GETTERS & SETTERS
             */
            get: function () {
                return this._isPaused;
            },
            set: function (value) {
                if (value) {
                    this._isPaused = true;
                    this.game.time.events.pause();
                    this.game.tweens.pauseAll();
                    if (this.level.pathManager) {
                        this.level.pathManager.pauseAll();
                    }
                }
                else {
                    this._isPaused = false;
                    this.game.time.events.resume();
                    this.game.tweens.resumeAll();
                    if (this.level.pathManager) {
                        this.level.pathManager.resumeAll();
                    }
                }
            },
            enumerable: true,
            configurable: true
        });
        /**
         * DESTROY METHOD
         */
        GameStateManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
        };
        return GameStateManager;
    }(Phaser.Group));
    src.GameStateManager = GameStateManager;
})(src || (src = {}));
var src;
(function (src) {
    var LevelManager = (function () {
        function LevelManager() {
            this.cachedLevel = new src.LevelObject([], [], src.Settings.DEFAULT_TENSION, src.Settings.POINTS_PER_SEGMENT, [], [], []);
        }
        Object.defineProperty(LevelManager, "instance", {
            get: function () {
                return LevelManager._instance ? LevelManager._instance
                    : LevelManager._instance = new LevelManager();
            },
            enumerable: true,
            configurable: true
        });
        LevelManager.prototype.loadLevel = function (level) {
            src.Settings.CURRENT_LEVEL = level;
            this.cachedLevel = src.LevelStorage.instance.getLevel(level);
        };
        return LevelManager;
    }());
    src.LevelManager = LevelManager;
})(src || (src = {}));
var src;
(function (src) {
    var PathManager = (function (_super) {
        __extends(PathManager, _super);
        function PathManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.level = level;
            return _this;
        }
        PathManager.prototype.buildPaths = function () {
            this.paths = [];
            for (var i = 0; i < src.LevelManager.instance.cachedLevel.paths.length; i++) {
                var path = this.add(new src.Path(this));
                this.paths.push(path);
                path.construct(src.LevelManager.instance.cachedLevel.paths[i], src.LevelManager.instance.cachedLevel.tension, src.LevelManager.instance.cachedLevel.resolution, src.LevelManager.instance.cachedLevel.balls[i]);
            }
        };
        PathManager.prototype.update = function () {
            if (!this.level.gameStateManager.isPaused) {
                _super.prototype.update.call(this);
            }
        };
        PathManager.prototype.start = function () {
            if (this.paths.length == 0) {
                return;
            }
            this.paths[0].pathInitializer.start();
        };
        PathManager.prototype.pathCleared = function (path) {
            var unclearedPaths = this.paths.reduce(function (counter, path) { return path.isCleared ? counter : counter + 1; }, 0);
            if (unclearedPaths == 0) {
                path.pathFinalizer.start();
            }
        };
        PathManager.prototype.pauseAll = function () {
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                path.speedManager.pause();
            }
        };
        PathManager.prototype.resumeAll = function () {
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                path.speedManager.resume();
            }
        };
        PathManager.prototype.dispatchPathLose = function (path) {
            this.paths.forEach(function (path) { return path.ballEaten(); });
        };
        PathManager.prototype.initializeNext = function (currentPath) {
            var currentIndex = this.paths.indexOf(currentPath);
            if (currentIndex == -1) {
                return;
            }
            if (currentIndex == this.paths.length - 1) {
                this.initializationCompleted();
                return;
            }
            this.paths[currentIndex + 1].pathInitializer.start();
        };
        PathManager.prototype.finalizeNext = function (currentPath) {
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                if (path != currentPath && !path.isFinished) {
                    path.pathFinalizer.start();
                }
            }
        };
        PathManager.prototype.getOnScreenColorsArray = function (except) {
            var availableColors = [];
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball.isAlive && (!except || ball.color != except)) {
                        availableColors.push(ball.color);
                    }
                }
            }
            return availableColors;
        };
        PathManager.prototype.getAvailableColorsArray = function () {
            var availableColors = [];
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball.isAlive) {
                        availableColors.push(ball.color);
                    }
                }
                for (var _d = 0, _e = path.ballManager.ballFactory.ballsQueue; _d < _e.length; _d++) {
                    var oncomingBall = _e[_d];
                    availableColors.push(oncomingBall.color);
                }
            }
            return availableColors;
        };
        PathManager.prototype.getCriticalColors = function () {
            var criticalColors = [];
            if (this.paths.length < 2) {
                return null;
            }
            var smallestPath = null;
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                if (path.ballManager.balls.length <= src.Settings.game.ZOOMER_PRIORITY_BALLS_LIMIT
                    && path.ballManager.getAliveBallsCount() > 0
                    && path.ballManager.getLastBall().getAbsolutePosition() > path.totalLength - src.Settings.game.ZOOMER_PRIORITY_DISTANCE
                    && (!smallestPath || path.ballManager.balls.length < smallestPath.ballManager.balls.length)) {
                    smallestPath = path;
                }
            }
            if (smallestPath && Math.random() < src.Settings.game.ZOOMER_PRIORITY_PROBABILITY) {
                for (var _b = 0, _c = smallestPath.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball.isAlive) {
                        criticalColors.push(ball.color);
                    }
                }
            }
            return criticalColors;
        };
        PathManager.prototype.getRandomVisibleBall = function () {
            var availableBalls = [];
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball.isAlive && ball.visible) {
                        availableBalls.push(ball);
                    }
                }
            }
            return (availableBalls.length > 0) ? Phaser.ArrayUtils.getRandomItem(availableBalls) : null;
        };
        PathManager.prototype.getRandomBallWithoutPowerup = function () {
            var availableBalls = [];
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball.isAlive && ball.visible && !ball.powerupActivator) {
                        availableBalls.push(ball);
                    }
                }
            }
            return (availableBalls.length > 0) ? Phaser.ArrayUtils.getRandomItem(availableBalls) : null;
        };
        PathManager.prototype.getPowerupsCount = function () {
            var powerupsCount = 0;
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball.isAlive && ball.powerupActivator) {
                        powerupsCount += 1;
                    }
                }
            }
            return powerupsCount;
        };
        PathManager.prototype.getBallsCount = function () {
            var ballsCount = 0;
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball.isAlive) {
                        ballsCount += 1;
                    }
                }
            }
            return ballsCount;
        };
        PathManager.prototype.getInitialBallsCount = function () {
            var ballsCount = 0;
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                ballsCount += path.ballManager.ballFactory.totalBalls;
            }
            return ballsCount;
        };
        PathManager.prototype.getFutureColorsArray = function (except) {
            var futureColors = [];
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.ballFactory.ballsQueue; _b < _c.length; _b++) {
                    var nextBall = _c[_b];
                    if (!except || nextBall.color != except) {
                        futureColors.push(nextBall.color);
                    }
                }
            }
            return futureColors;
        };
        PathManager.prototype.getGapBonusesCount = function (ball) {
            var gapBonuses = 0;
            for (var _i = 0, _a = this.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                gapBonuses += path.ballManager.getGapBonusesCount(ball);
            }
            return gapBonuses;
        };
        /**
         * PRIVATE
         */
        PathManager.prototype.initializationCompleted = function () {
            this.level.gameStateManager.startBalls();
        };
        /**
         *  DESTROY METHOD
         */
        PathManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.paths = null;
        };
        return PathManager;
    }(Phaser.Group));
    src.PathManager = PathManager;
})(src || (src = {}));
var src;
(function (src) {
    var PowerupManager = (function (_super) {
        __extends(PowerupManager, _super);
        function PowerupManager(level) {
            var _this = _super.call(this, level.game, null) || this;
            _this.countdown = src.Settings.game.POWERUP_TIMER;
            _this.cooldown = src.Settings.game.POWERUP_COOLDOWN;
            _this.level = level;
            _this.powerUps = [];
            _this.chances = [
                src.Settings.game.SLOWDOWN_APPEARING_CHANCE,
                src.Settings.game.REWIND_APPEARING_CHANCE,
                src.Settings.game.BOMB_APPEARING_CHANCE,
                src.Settings.game.LIGHTING_APPEARING_CHANCE,
                src.Settings.game.LASER_APPEARING_CHANCE,
                src.Settings.game.FIREBALL_APPEARING_CHANCE
            ];
            return _this;
        }
        PowerupManager.prototype.activatePowerup = function (powerupType, ball) {
            if (this.hasAlivePowerups(powerupType)) {
                this.getAlivePowerup(powerupType).refresh(ball);
                return;
            }
            var powerup = null;
            switch (powerupType) {
                case src.PowerupType.SLOWDOWN:
                    powerup = new src.SlowdownPowerup(this, ball);
                    break;
                case src.PowerupType.REWIND:
                    powerup = new src.RewindPowerup(this, ball);
                    break;
                case src.PowerupType.BOMB:
                    powerup = new src.BombPowerup(this, ball);
                    break;
                case src.PowerupType.LIGHTING:
                    if (ball.visible) {
                        powerup = new src.LightingPowerup(this, ball);
                    }
                    break;
                case src.PowerupType.LASER:
                    powerup = new src.LaserPowerup(this, ball);
                    break;
                case src.PowerupType.FIREBALL:
                    powerup = new src.FireballPowerup(this, ball);
                    break;
            }
            if (powerup) {
                this.add(powerup);
                this.powerUps.push(powerup);
            }
        };
        PowerupManager.prototype.hasAlivePowerups = function (powerupType) {
            for (var _i = 0, _a = this.powerUps; _i < _a.length; _i++) {
                var powerup = _a[_i];
                if (powerup.powerupType == powerupType && powerup.isContinuous) {
                    return true;
                }
            }
            return false;
        };
        PowerupManager.prototype.getAlivePowerup = function (powerupType) {
            for (var _i = 0, _a = this.powerUps; _i < _a.length; _i++) {
                var powerup = _a[_i];
                if (powerup.powerupType == powerupType && powerup.isContinuous) {
                    return powerup;
                }
            }
            return null;
        };
        PowerupManager.prototype.hasActivePowerup = function (powerupType) {
            for (var _i = 0, _a = this.powerUps; _i < _a.length; _i++) {
                var powerup = _a[_i];
                if (powerup.powerupType == powerupType && powerup.isContinuous && powerup.isActive) {
                    return true;
                }
            }
            return false;
        };
        PowerupManager.prototype.update = function () {
            if (this.level.gameStateManager.isPaused) {
                return;
            }
            _super.prototype.update.call(this);
            if (this.level.gameStateManager.hasLosingPaths) {
                return;
            }
            this.cooldown -= this.game.time.elapsedMS;
            this.countdown -= this.game.time.elapsedMS;
            if (this.countdown < 0 && this.cooldown < 0) {
                this.activateRandomPowerup();
                this.countdown = src.Settings.game.POWERUP_TIMER * (1 + this.game.rnd.realInRange(-src.Settings.game.POWERUP_TIMER_DEVIATION, src.Settings.game.POWERUP_TIMER_DEVIATION));
            }
            for (var i = 0; i < this.chances.length; i++) {
                if (src.Settings.ENABLE_DEBUG_OUTPUT) {
                    this.game.debug.text('' + Phaser.Math.roundTo(this.chances[i], -2), 200 + i * 50, 12, "#ffc7d2");
                }
            }
        };
        PowerupManager.prototype.testRandomPowerup = function (powerupType) {
            var activePowerups = this.level.pathManager.getPowerupsCount();
            if (activePowerups >= src.Settings.game.MAX_ACTIVE_POWERUPS || activePowerups > this.level.pathManager.getBallsCount() / 3) {
                return;
            }
            var randomBall = this.level.pathManager.getRandomBallWithoutPowerup();
            if (!randomBall) {
                return;
            }
            randomBall.createPowerup(powerupType);
            this.clearChances(powerupType, true);
            this.cooldown = src.Settings.game.POWERUP_COOLDOWN;
            this.increaseChancesExcept(powerupType);
        };
        /**
         * DISPATCHERS
         */
        PowerupManager.prototype.dispatchComboAppearing = function (multiplier) {
            if (this.cooldown < 0 && multiplier > 1) {
                this.activateRandomPowerup();
            }
        };
        PowerupManager.prototype.dispatchGapBonusAppearing = function (multiplier) {
            if (this.cooldown < 0 && multiplier > 0) {
                this.activateRandomPowerup();
            }
        };
        /**
         * PRIVATE
         */
        PowerupManager.prototype.activateRandomPowerup = function () {
            var activePowerups = this.level.pathManager.getPowerupsCount();
            if (activePowerups >= src.Settings.game.MAX_ACTIVE_POWERUPS || activePowerups > this.level.pathManager.getBallsCount() / 3) {
                return;
            }
            var randomBall = this.level.pathManager.getRandomBallWithoutPowerup();
            if (!randomBall) {
                return;
            }
            var powerupType = this.selectRandomPowerup();
            if (powerupType != null) {
                randomBall.createPowerup(powerupType);
                this.clearChances(powerupType, true);
                this.cooldown = src.Settings.game.POWERUP_COOLDOWN;
                this.increaseChancesExcept(powerupType);
            }
        };
        PowerupManager.prototype.selectRandomPowerup = function () {
            var powerupTypes = [src.PowerupType.LASER, src.PowerupType.LIGHTING, src.PowerupType.REWIND, src.PowerupType.SLOWDOWN, src.PowerupType.BOMB, src.PowerupType.FIREBALL];
            for (var i = powerupTypes.length - 1; i > -1; i--) {
                if (Math.random() > this.getChance(powerupTypes[i])) {
                    powerupTypes.splice(i, 1);
                }
            }
            return (powerupTypes.length > 0) ? Phaser.ArrayUtils.getRandomItem(powerupTypes) : null;
        };
        PowerupManager.prototype.getChance = function (powerupType) {
            return this.chances[powerupType];
        };
        PowerupManager.prototype.clearChances = function (powerupType, setZero) {
            if (setZero === void 0) { setZero = false; }
            switch (powerupType) {
                case src.PowerupType.SLOWDOWN:
                    this.chances[powerupType] = setZero ? 0 : this.chances[powerupType] < 0 ? ~~(this.chances[powerupType] + 1) : src.Settings.game.SLOWDOWN_APPEARING_CHANCE;
                    break;
                case src.PowerupType.REWIND:
                    this.chances[powerupType] = setZero ? -2 : this.chances[powerupType] < 0 ? ~~(this.chances[powerupType] + 1) : src.Settings.game.REWIND_APPEARING_CHANCE;
                    break;
                case src.PowerupType.BOMB:
                    this.chances[powerupType] = setZero ? 0 : this.chances[powerupType] < 0 ? ~~(this.chances[powerupType] + 1) : src.Settings.game.BOMB_APPEARING_CHANCE;
                    break;
                case src.PowerupType.LIGHTING:
                    this.chances[powerupType] = setZero ? 0 : this.chances[powerupType] < 0 ? ~~(this.chances[powerupType] + 1) : src.Settings.game.LIGHTING_APPEARING_CHANCE;
                    break;
                case src.PowerupType.LASER:
                    this.chances[powerupType] = setZero ? 0 : this.chances[powerupType] < 0 ? ~~(this.chances[powerupType] + 1) : src.Settings.game.LASER_APPEARING_CHANCE;
                    break;
                case src.PowerupType.FIREBALL:
                    this.chances[powerupType] = setZero ? 0 : this.chances[powerupType] < 0 ? ~~(this.chances[powerupType] + 1) : src.Settings.game.FIREBALL_APPEARING_CHANCE;
                    break;
            }
        };
        PowerupManager.prototype.increaseChancesExcept = function (selectedType) {
            var powerupTypes = [src.PowerupType.LASER, src.PowerupType.LIGHTING, src.PowerupType.REWIND, src.PowerupType.SLOWDOWN, src.PowerupType.BOMB, src.PowerupType.FIREBALL];
            for (var i = powerupTypes.length - 1; i > -1; i--) {
                if (selectedType != powerupTypes[i]) {
                    if (this.chances[powerupTypes[i]] <= 0) {
                        this.clearChances(powerupTypes[i]);
                    }
                    this.chances[powerupTypes[i]] *= src.Settings.game.CHANCE_APPEARING_MULTIPLIER;
                }
            }
        };
        /**
         *  DESTROY METHOD
         */
        PowerupManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.powerUps = null;
        };
        return PowerupManager;
    }(Phaser.Group));
    src.PowerupManager = PowerupManager;
})(src || (src = {}));
var src;
(function (src) {
    var ScoreManager = (function () {
        function ScoreManager() {
            this.currentScore = 0;
            window.famobi_analytics.trackEvent("EVENT_LIVESCORE", {liveScore: this.currentScore});
        }
        Object.defineProperty(ScoreManager, "instance", {
            get: function () {
                return ScoreManager._instance ? ScoreManager._instance : ScoreManager._instance = new ScoreManager();
            },
            enumerable: true,
            configurable: true
        });
        ScoreManager.prototype.init = function (scores) {
            this.scores = scores.slice();
        };
        ScoreManager.prototype.update = function () {
        };
        ScoreManager.prototype.clear = function () {
            this.currentScore = 0;
            window.famobi_analytics.trackEvent("EVENT_LIVESCORE", {liveScore: this.currentScore});
        };
        ScoreManager.prototype.calculateScores = function (numBalls) {
            return 10 * numBalls;
        };
        ScoreManager.prototype.displayScores = function (scores, displayScores, color, x, y, delay, randomizeXPosition, randomizeYPosition, targetScale, playPopSound) {
            if (displayScores === void 0) { displayScores = false; }
            if (color === void 0) { color = src.BallColor.RED; }
            if (x === void 0) { x = 0; }
            if (y === void 0) { y = 0; }
            if (delay === void 0) { delay = 5; }
            if (randomizeXPosition === void 0) { randomizeXPosition = false; }
            if (randomizeYPosition === void 0) { randomizeYPosition = false; }
            if (targetScale === void 0) { targetScale = 0.9; }
            if (playPopSound === void 0) { playPopSound = false; }
            if (displayScores && src.App.instance.state.getCurrentState() instanceof src.Level) {
                src.App.instance.state.getCurrentState().effectsManager.addScoresEffect(randomizeXPosition ? Phaser.Math.random(x - 50, x + 50) : x, randomizeYPosition ? Phaser.Math.random(y - 50, y + 50) : y, scores, color, delay, targetScale, playPopSound);
            }
        };
        ScoreManager.prototype.addScores = function (scores) {
            this.currentScore += scores;
            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_LIVESCORE, {
                liveScore: this.currentScore
            });

        };
        ScoreManager.prototype.getLevelScores = function (level) {
            return this.scores[level - 1];
        };
        ScoreManager.prototype.getTotalScores = function () {
            return this.scores.reduce(function (sum, currentScore) { return sum + currentScore; }, 0);
        };
        ScoreManager.prototype.getScores = function () {
            return this.scores.slice();
        };
        ScoreManager.prototype.updateLevelScores = function (level, newScore) {
            if (this.getLevelScores(level) < newScore) {
                this.scores[level - 1] = newScore;
                return true;
            }
            else {
                return false;
            }
        };
        ScoreManager._instance = null;
        return ScoreManager;
    }());
    src.ScoreManager = ScoreManager;
})(src || (src = {}));
var src;
(function (src) {
    var StatsManager = (function () {
        function StatsManager() {
            this.clear();
        }
        Object.defineProperty(StatsManager, "instance", {
            get: function () {
                return StatsManager._instance ? StatsManager._instance : StatsManager._instance = new StatsManager();
            },
            enumerable: true,
            configurable: true
        });
        StatsManager.prototype.update = function () {
            this.time += src.App.instance.time.elapsedMS;
        };
        StatsManager.prototype.clear = function () {
            this.balls = 0;
            this.combos = 0;
            this.gaps = 0;
            this.time = 0;
            this.coins = 0;
            this.bonus = 0;
            this._ballsScore = 0;
            this._combosScore = 0;
            this._gapsScore = 0;
            this._timeScore = 0;
            this._bonusScore = 0;
        };
        StatsManager.prototype.addCoin = function () {
            this.coins += 1;
            src.ScoreManager.instance.addScores(1 * src.Settings.game.COIN_SCORE);
        };
        StatsManager.prototype.addBalls = function (count) {
            this.balls += count;
        };
        StatsManager.prototype.addGaps = function (count) {
            this.gaps += count;
        };
        StatsManager.prototype.addCombos = function (count) {
            this.combos += count;
        };
        StatsManager.prototype.addComboBonusScore = function (bonusScore) {
            this._combosScore += bonusScore;
        };
        StatsManager.prototype.addGapBonusScore = function (bonusScore) {
            this._gapsScore += bonusScore;
        };
        StatsManager.prototype.addBonus = function (count) {
            this.bonus += count;
        };
        StatsManager.prototype.calculateReward = function () {
            return this.ballsScore + this.combosScore + this.gapsScore + this.timeScore + this.bonusScore;
        };
        Object.defineProperty(StatsManager.prototype, "coins", {
            /**
             * GETTERS & SETTERS
             */
            get: function () {
                return this._coins;
            },
            set: function (value) {
                this._coins = value;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "time", {
            get: function () {
                return this._time;
            },
            set: function (value) {
                this._time = value;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "gaps", {
            get: function () {
                return this._gaps;
            },
            set: function (value) {
                this._gaps = value;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "combos", {
            get: function () {
                return this._combos;
            },
            set: function (value) {
                this._combos = value;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "balls", {
            get: function () {
                return this._balls;
            },
            set: function (value) {
                this._balls = value;
                this._ballsScore = this._balls * src.Settings.game.BALL_SCORE;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "bonus", {
            get: function () {
                return this._bonus;
            },
            set: function (value) {
                this._bonus = value;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "timeScore", {
            /**
             * SCORES
             */
            get: function () {
                if (src.App.instance.state.getCurrentState() instanceof src.Level) {
                    return this._timeScore = src.App.instance.state.getCurrentState().pathManager.getInitialBallsCount() * 10 - src.Settings.game.TIME_BONUS_POINTS_PER_SECOND_PENALTY * ~~(this.time / 1000);
                }
                else {
                    return this._timeScore = this.balls * 10 - src.Settings.game.TIME_BONUS_POINTS_PER_SECOND_PENALTY * ~~(this.time / 1000);
                }
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "gapsScore", {
            get: function () {
                return this._gapsScore;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "combosScore", {
            get: function () {
                return this._combosScore;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "ballsScore", {
            get: function () {
                return this._ballsScore;
            },
            enumerable: true,
            configurable: true
        });
        Object.defineProperty(StatsManager.prototype, "bonusScore", {
            get: function () {
                return this._bonusScore = this.bonus * src.Settings.game.PATH_FINISHED_BONUS_SCORE + this.coins * src.Settings.game.COIN_SCORE;
            },
            enumerable: true,
            configurable: true
        });
        StatsManager._instance = null;
        return StatsManager;
    }());
    src.StatsManager = StatsManager;
})(src || (src = {}));
var src;
(function (src) {
    var TouchInputManager = (function (_super) {
        __extends(TouchInputManager, _super);
        function TouchInputManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.level = level;
            _this.createHandlers();
            return _this;
        }
        /**
         * HANDLERS
         */
        TouchInputManager.prototype.createHandlers = function () {
            if (this.game.device.desktop) {
                src.App.instance.input.onDown.add(this.onInputTapHandler, this);
            }
            else {
                src.App.instance.input.onUp.add(this.onInputTapHandler, this);
            }
        };
        TouchInputManager.prototype.destroyHandlers = function () {
            src.App.instance.input.onDown.removeAll();
        };
        /**
         * PRIVATE METHODS
         */
        TouchInputManager.prototype.onInputTapHandler = function (pointer) {
            if (this.level.gameStateManager.isPaused || pointer.targetObject) {
                return;
            }
            if (this.game.device.desktop && pointer instanceof Phaser.Pointer) {
                if (pointer.leftButton.isDown) {
                    this.level.cannonManager.handleTap();
                }
                if (pointer.rightButton.isDown) {
                    this.level.cannonManager.handleSwap();
                }
            }
            else {
                this.level.cannonManager.handleTap();
            }
        };
        /**
         * DESTROY METHOD
         */
        TouchInputManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.destroyHandlers();
            this.level = null;
        };
        return TouchInputManager;
    }(Phaser.Group));
    src.TouchInputManager = TouchInputManager;
})(src || (src = {}));
var src;
(function (src) {
    var TunnelManager = (function (_super) {
        __extends(TunnelManager, _super);
        function TunnelManager(path) {
            var _this = _super.call(this, path.game) || this;
            _this.path = path;
            _this.level = path.pathManager.level;
            return _this;
        }
        TunnelManager.prototype.buildTunnels = function () {
            var _this = this;
            this.tunnels = [];
            //filter only tunnels that belongs to current path
            var currentPathTunnels = src.LevelManager.instance.cachedLevel.tunnels.filter(function (tunnelObject) {
                return tunnelObject[0] == _this.level.pathManager.paths.indexOf(_this.path);
            });
            //sort tunnels array
            currentPathTunnels = currentPathTunnels.sort(function (tunnelObjectA, tunnelObjectB) {
                return (tunnelObjectA[1] <= tunnelObjectB[1]) ? -1 : 1;
            });
            //build tunnels
            for (var _i = 0, currentPathTunnels_1 = currentPathTunnels; _i < currentPathTunnels_1.length; _i++) {
                var tunnelObject = currentPathTunnels_1[_i];
                var tunnel = this.add(new src.Tunnel(this, this.path, tunnelObject[1] + 1, tunnelObject[2], tunnelObject[3] + 1, tunnelObject[4]));
                this.tunnels.push(tunnel);
            }
        };
        /**
         * PRIVATE METHODS
         */
        /**
         *  DESTROY METHOD
         */
        TunnelManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
            this.tunnels = null;
        };
        return TunnelManager;
    }(Phaser.Group));
    src.TunnelManager = TunnelManager;
})(src || (src = {}));
var src;
(function (src) {
    var UIManager = (function (_super) {
        __extends(UIManager, _super);
        function UIManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.currentScoreValue = 0;
            _this.level = level;
            _this.createButtons();
            return _this;
        }
        UIManager.prototype.update = function () {
            if (!this.level.gameStateManager.isPaused) {
                this.updateScores();
            }
        };
        UIManager.prototype.updateScores = function (speedMultiplier) {
            if (speedMultiplier === void 0) { speedMultiplier = 0.8; }
            _super.prototype.update.call(this);
            if (this.currentScoreValue != src.ScoreManager.instance.currentScore) {
                if (Math.abs(this.currentScoreValue - src.ScoreManager.instance.currentScore) < 20) {
                    this.game.tweens.removeFrom(this);
                    this.currentScoreValue = src.ScoreManager.instance.currentScore;
                }
                else {
                    this.game.tweens.removeFrom(this);
                    this.game.add.tween(this)
                        .to({ currentScoreValue: src.ScoreManager.instance.currentScore }, 180 + Math.pow(Math.abs(src.ScoreManager.instance.currentScore - this.currentScoreValue), speedMultiplier), Phaser.Easing.Sinusoidal.Out, true);
                }
            }
            this.scoresValue.text = '' + (~~this.currentScoreValue);
            this.scoresContainer.x = 303 - (this.scoresValue.text.length - 1) * 10;
            if (src.Settings.DISPLAY_FPS) {
                this.debugOutput.text = '' + this.game.time.fps;
            }
        };
        /**
         * PRIVATE METHODS
         */
        UIManager.prototype.createButtons = function () {
            this.buttonPause = this.add(src.ButtonUtils.createButton(src.Settings.GAME_ATLAS, 'buttonPause', 543.5, 31, this.pauseClicked, this));
            this.levelIconLeft = this.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2 - (src.Settings.CURRENT_LEVEL > 9 ? 20 : 15), src.CustomScaleManager.ORIGINAL_HEIGHT - 18, src.Settings.GAME_ATLAS, 'levelIcon0000'));
            this.levelIconLeft.anchor.set(1, 0.5);
            this.levelIconRight = this.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2 + (src.Settings.CURRENT_LEVEL > 9 ? 20 : 15), src.CustomScaleManager.ORIGINAL_HEIGHT - 18, src.Settings.GAME_ATLAS, 'levelIcon0000'));
            this.levelIconRight.scale.set(-1, 1);
            this.levelIconRight.anchor.set(1, 0.5);
            this.levelText = this.add(src.TextUtils.getShadowText('' + src.Settings.CURRENT_LEVEL, src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT - 17, 28, '#FFFFFF', '#2E2E2E', 0, 3, 0.5));
            this.scoresContainer = this.add(this.game.make.group(null));
            this.scoresContainer.position.set(300, 34);
            this.scoresIcon = this.scoresContainer.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'cupIcon0000'));
            this.scoresIcon.scale.set(0.9);
            this.scoresIcon.anchor.set(0.5, 0.5);
            this.scoresValue = this.scoresContainer.add(src.TextUtils.getShadowText('' + src.ScoreManager.instance.currentScore, 30, 4, 42, '#FFFFFF', '#2E2E2E', 0, 3, 0.5));
            this.scoresValue.anchor.set(0, 0.5);
            if (src.Settings.DISPLAY_FPS) {
                this.debugOutput = this.add(src.TextUtils.getShadowText('', 15, 15, 25, '#FFFFFF', '#2E2E2E', 0, 3, 0.5));
            }
        };
        UIManager.prototype.pauseClicked = function () {
            this.level.gameStateManager.pauseLevel();
            this.game.sound.play('click', 0.9);
        };
        /**
         * DESTROY METHOD
         */
        UIManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.level = null;
        };
        return UIManager;
    }(Phaser.Group));
    src.UIManager = UIManager;
})(src || (src = {}));
var src;
(function (src) {
    var WayManager = (function (_super) {
        __extends(WayManager, _super);
        function WayManager(level) {
            var _this = _super.call(this, level.game) || this;
            _this.level = level;
            if (!WayManager.bitmapData) {
                WayManager.bitmapData = _this.game.make.bitmapData(src.CustomScaleManager.ORIGINAL_WIDTH, src.CustomScaleManager.ORIGINAL_HEIGHT, 'levelBitmap' + src.Settings.CURRENT_LEVEL);
            }
            _this.pattern = _this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'pathSegment1' + '0000');
            _this.pattern.anchor.set(0.5);
            _this.particle = _this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS);
            _this.particle.anchor.set(0.5);
            _this.shadowLight = _this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'pathSegmentShadowLight' + '0000');
            _this.shadowLight.anchor.set(0.5);
            _this.shadowDark = _this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'pathSegmentShadowDark' + '0000');
            _this.shadowDark.anchor.set(0.5);
            WayManager.bitmapData.clear();
            _this.waySprite = _this.add(_this.game.make.sprite(0, 0, WayManager.bitmapData));
            return _this;
        }
        WayManager.prototype.buildTexture = function () {
            // var timeStart = performance.now();
            this.drawParticles();
            this.drawToBitmapData(this.shadowDark, src.Settings.PATH_SHADOW_DELTA, src.Settings.PATH_SHADOW_DELTA);
            this.drawToBitmapData(this.shadowLight, src.Settings.PATH_LIGHT_DELTA, src.Settings.PATH_LIGHT_DELTA);
            this.drawToBitmapData(this.pattern, 0, 0);
            // var timeEnd = performance.now();
            // console.log("Drawing a way took " + Math.round(timeEnd - timeStart) + " milliseconds.")
        };
        /**
         * PRIVATE METHODS
         */
        WayManager.prototype.drawParticles = function () {
            for (var _i = 0, _a = this.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.tunnelManager.tunnels; _b < _c.length; _b++) {
                    var tunnel = _c[_b];
                    var startPosition = path.calculateRelativePosition(tunnel.startPosition, -5);
                    var endPosition = tunnel.endPosition;
                    var currentPosition = startPosition >= 0 ? startPosition : tunnel.startPosition;
                    var prevPosition = path.getConcretePosition(startPosition ? path.calculateRelativePosition(startPosition, -5) : tunnel.startPosition - 0.00001);
                    while (currentPosition < endPosition) {
                        var targetPosition = path.getConcretePosition(currentPosition);
                        var distance = this.drawStoneParticle(targetPosition, prevPosition);
                        currentPosition = path.calculateRelativePosition(currentPosition, distance);
                        prevPosition = targetPosition;
                    }
                }
            }
        };
        WayManager.prototype.drawToBitmapData = function (pattern, dx, dy) {
            for (var _i = 0, _a = this.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                var pathIndex = this.level.pathManager.paths.indexOf(path);
                var patternFrame = (src.Settings.game.PATH_GENERATOR_USE_SINGLE_COLOR || pathIndex == 0 ? 0 : (pathIndex % 2 != 0) ? 2 : 1);
                this.pattern.frameName = "pathSegment" + patternFrame + '0000';
                for (var i = 0; i < path.pathPoints.length - 1; i++) {
                    var pathPoint = path.pathPoints[i];
                    var nextPathPoint = path.pathPoints[i + 1];
                    if (!path.isVisible(pathPoint.chainIndex)) {
                        continue;
                    }
                    for (var j = 0; j < pathPoint.pathLength; j += src.Settings.PATTERN_DRAWING_INTERVAL) {
                        var targetPosition = src.AdvancedMath.pointOnSegment(pathPoint.x, pathPoint.y, nextPathPoint.x, nextPathPoint.y, j);
                        WayManager.bitmapData.draw(pattern, targetPosition.x + dx, targetPosition.y + dy);
                    }
                }
            }
        };
        WayManager.prototype.drawStoneParticle = function (targetPosition, prevPosition) {
            this.particle.frameName = Math.random() > 0.5 ? "x10000" : "x20000";
            this.particle.rotation = prevPosition ? Phaser.Math.angleBetweenPoints(prevPosition, targetPosition) + Math.PI / 2 : 0;
            WayManager.bitmapData.draw(this.particle, targetPosition.x, targetPosition.y);
            this.particle.rotation = 0;
            return this.particle.height + this.game.rnd.integerInRange(-5, 5);
        };
        /**
         *  DESTROY METHOD
         */
        WayManager.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.particle = null;
            this.pattern = null;
            this.shadowLight = null;
            this.shadowDark = null;
            this.waySprite = null;
            this.level = null;
        };
        return WayManager;
    }(Phaser.Group));
    src.WayManager = WayManager;
})(src || (src = {}));
var src;
(function (src) {
    var WindowManager = (function () {
        function WindowManager() {
            // public tutorial: Tutorial;
            this.isInitialized = false;
        }
        Object.defineProperty(WindowManager, "instance", {
            get: function () {
                return WindowManager._instance ? WindowManager._instance : WindowManager._instance = new WindowManager();
            },
            enumerable: true,
            configurable: true
        });
        WindowManager.prototype.init = function () {
            this.transitionScreen = new src.TransitionScreen();
            this.credits = new src.CreditsWindow();
            this.results = new src.ResultsWindow();
            this.pause = new src.PauseWindow();
            this.defeat = new src.DefeatWindow();
            // this.tutorial = new Tutorial();
            this.isInitialized = true;
        };
        WindowManager.prototype.resize = function () {
            if (this.isInitialized) {
                this.transitionScreen.resize();
                this.credits.resize();
                this.results.resize();
                this.pause.resize();
                this.defeat.resize();
                //this.tutorial.resize();
            }
        };
        WindowManager.prototype.showCredits = function () {
            this.credits.show();
        };
        WindowManager.prototype.showResults = function () {
            this.results.show();
        };
        WindowManager.prototype.showPause = function () {
            this.pause.show();
        };
        WindowManager.prototype.showDefeat = function () {
            this.defeat.show();
        };
        WindowManager.prototype.showTutorial = function () {
            // this.tutorial.show();
        };
        /**
         * TRANSITION
         */
        WindowManager.prototype.isTransitionActive = function () {
            return this.transitionScreen.isActive;
        };
        WindowManager.prototype.transitionTo = function (stateName, callback, clearWorld) {
            if (callback === void 0) { callback = null; }
            if (clearWorld === void 0) { clearWorld = true; }
            this.transitionScreen.start(function () {
                if (callback) {
                    callback();
                }
                src.App.instance.state.start(stateName, clearWorld);
            });
        };
        WindowManager.prototype.endTransition = function () {
            if (this.isTransitionActive()) {
                this.transitionScreen.finish();
            }
        };
        WindowManager._instance = null;
        return WindowManager;
    }());
    src.WindowManager = WindowManager;
})(src || (src = {}));
var src;
(function (src) {
    var Ball = (function (_super) {
        __extends(Ball, _super);
        function Ball(ballManager, path, color, relativePosition, parent, startPosition) {
            if (parent === void 0) { parent = null; }
            if (startPosition === void 0) { startPosition = null; }
            var _this = _super.call(this, src.App.instance, parent ? parent : ballManager) || this;
            _this._prev = null;
            _this._next = null;
            _this.id = 0;
            _this.color = null;
            _this.segmentProgress = 0;
            _this.distanceToTarget = 0;
            _this.insertionSpeedMultiplier = 1;
            _this.previousPosition = 0;
            _this.powerupActivator = null;
            _this.powerupType = null;
            _this.comboMultiplier = 1;
            _this.comboSoundIndex = 1;
            _this.previousScore = 0;
            _this.gapBonus = 0;
            _this._backwardSpeed = 0;
            _this.isAlive = true;
            _this.onTheWay = true;
            _this.isUnderground = false;
            _this.touchingPrev = true;
            _this.id = Ball.ID++;
            _this.ballManager = ballManager;
            _this.path = path;
            _this.color = color;
            _this.freeBallStartPosition = startPosition;
            _this.comboSoundIndex = _this.game.rnd.integerInRange(0, 3);
            _this.createContent();
            _this.updatePosition(relativePosition);
            return _this;
        }
        Ball.prototype.update = function () {
            _super.prototype.update.call(this);
        };
        Ball.prototype.updateContacts = function () {
            if (!this.isAlive || !this.onTheWay) {
                return;
            }
            if (this.getPrev()) {
                var hitsPrevious = this.isTouching(this.getPrev(), false);
                if (hitsPrevious && !this.touchingPrev) {
                    this.touchingPrev = hitsPrevious;
                    this.ballManager.dispatchGapDestroyingBetween(this, this.getPrev());
                }
                this.touchingPrev = hitsPrevious;
            }
        };
        Ball.prototype.createContent = function () {
            this.view = this.add(new src.AnimatedBallView(this, this.color));
            // let idText: Phaser.Text = this.game.make.text(0, 0, '' + this.id);
            // idText.anchor.set(0.5);
            // this.add(idText);
        };
        Ball.prototype.addToParent = function () {
            if (this.parent) {
                this.parent.removeChild(this);
            }
            this.ballManager.add(this);
        };
        Ball.prototype.moveTo = function (x, y) {
            this.updateRotation();
            this.view.move(x - this.x, y - this.y);
            this.position.set(x, y);
            this.isUnderground = this.path.isUnderground(this.getRelativePosition());
            this.visible = this.path.isVisible(this.getRelativePosition());
        };
        Ball.prototype.updateRotation = function () {
            if (this.getNext() && this.getNext().onTheWay && Phaser.Math.distance(this.x, this.y, this.getNext().x, this.getNext().y) < 2 * src.Settings.BALL_DIAMETER) {
                this.view.ballBackground.rotation = this.game.physics.arcade.angleBetween(this, this.getNext());
            }
            else {
                if (this.pathPoint && this.pathPoint.next) {
                    this.view.ballBackground.rotation = this.game.physics.arcade.angleBetween(this.pathPoint, this.pathPoint.next);
                }
            }
        };
        Ball.prototype.updatePosition = function (relativePosition) {
            if (!this.isAlive) {
                return;
            }
            if (relativePosition == -1) {
                if (Math.abs(this.path.totalLength - this.getAbsolutePosition()) < Math.abs(this.getAbsolutePosition())) {
                    this.reachFinish();
                }
                else {
                    this.killBall();
                }
                return;
            }
            this.previousPosition = this.getRelativePosition();
            this.pathPoint = this.path.getPathPoint(relativePosition);
            this.segmentProgress = src.AdvancedMath.getDecimal(relativePosition) * this.pathPoint.pathLength;
            if (this.onTheWay) {
                var newPosition = this.path.getConcretePosition(relativePosition);
                this.moveTo(newPosition.x, newPosition.y);
            }
            else {
                this.updateWhileInserting(relativePosition);
            }
        };
        Ball.prototype.updateWhileInserting = function (relativePosition) {
            var targetPosition = this.path.getConcretePosition(relativePosition);
            this.distanceToTarget = Phaser.Math.distance(this.x, this.y, targetPosition.x, targetPosition.y);
            var insertionSpeed = Math.max(src.Settings.game.FREE_BALL_INSERTION_SPEED, src.Settings.game.getBallSpeed() * src.Settings.game.FREE_BALL_INSERTION_SPEED_MULTIPLIER, this.ballManager.path.speedManager.getChainSpeed() * src.Settings.game.FREE_BALL_INSERTION_SPEED_MULTIPLIER);
            var distance = insertionSpeed * this.insertionSpeedMultiplier * (src.Settings.REALTIME_CALCULATIONS ? this.game.time.elapsedMS / 1000 : this.game.time.physicsElapsed);
            var nextPosition = src.AdvancedMath.pointOnSegment(this.x, this.y, targetPosition.x, targetPosition.y, distance);
            var distanceToNextPosition = Phaser.Math.distance(this.x, this.y, nextPosition.x, nextPosition.y);
            if (distanceToNextPosition >= this.distanceToTarget) {
                this.insertIntoLine();
                this.moveTo(targetPosition.x, targetPosition.y);
            }
            else {
                this.moveTo(nextPosition.x, nextPosition.y);
            }
        };
        Ball.prototype.insertIntoLine = function () {
            var _this = this;
            this.gapBonus = this.path.pathManager.getGapBonusesCount(this);
            this.distanceToTarget = 0;
            this.onTheWay = true;
            this.addToParent();
            this.game.time.events.add(src.Settings.INSERT_BALL_REACTION_DELAY, function () {
                if (_this.ballManager) {
                    _this.ballManager.dispatchAddingBallToTheChain(_this);
                }
            });
        };
        Ball.prototype.stepForward = function (speed) {
            if (this.isAlive) {
                var relativePosition = this.path.calculateRelativePosition(this.getRelativePosition(), speed * (src.Settings.REALTIME_CALCULATIONS ? this.game.time.elapsedMS / 1000 : this.game.time.physicsElapsed));
                this.updatePosition(relativePosition);
            }
        };
        Ball.prototype.stepBackward = function (speed) {
            if (this.isAlive) {
                var relativePosition = this.ballManager.path.calculateRelativePosition(this.getRelativePosition(), speed * (src.Settings.REALTIME_CALCULATIONS ? this.game.time.elapsedMS / 1000 : this.game.time.physicsElapsed));
                this.updatePosition(relativePosition);
            }
        };
        Ball.prototype.getNextRelativePosition = function () {
            if (this.onTheWay) {
                return this.ballManager.path.calculateRelativePosition(this.getRelativePosition(), src.Settings.BALL_DIAMETER);
            }
            else {
                if (!this.getPrev() || !this.isTouching(this.getPrev())) {
                    return this.ballManager.path.calculateRelativePosition(this.getRelativePosition(), src.Settings.BALL_DIAMETER);
                }
                else {
                    if (this.distanceToTarget > src.Settings.BALL_DIAMETER) {
                        return this.getRelativePosition();
                    }
                    else {
                        return this.ballManager.path.calculateRelativePosition(this.getRelativePosition(), src.Settings.BALL_DIAMETER - this.distanceToTarget);
                    }
                }
            }
        };
        Ball.prototype.getPrevRelativePosition = function () {
            return this.ballManager.path.calculateRelativePosition(this.getRelativePosition(), -src.Settings.BALL_DIAMETER);
        };
        Ball.prototype.getRelativePosition = function () {
            if (!this.pathPoint || !this.isAlive) {
                return -1;
            }
            return this.pathPoint.chainIndex + (this.pathPoint.pathLength > 0 ? (this.segmentProgress / this.pathPoint.pathLength) : 0);
        };
        Ball.prototype.getAbsolutePosition = function () {
            if (!this.pathPoint || !this.isAlive) {
                return -1;
            }
            return this.pathPoint.startPosition + this.segmentProgress;
        };
        Ball.prototype.isTouching = function (anotherBall, highPrecision) {
            if (highPrecision === void 0) { highPrecision = true; }
            return Phaser.Math.distance(this.x, this.y, anotherBall.x, anotherBall.y) <= src.Settings.BALL_DIAMETER + (highPrecision ? 0 : 1);
        };
        Ball.prototype.createPowerup = function (powerupType, silent) {
            if (silent === void 0) { silent = false; }
            if (!this.powerupActivator) {
                if (this.parent && this.parent instanceof Phaser.Group) {
                    this.parent.bringToTop(this);
                }
                this.powerupActivator = this.view.add(new src.PowerupActivator(this, powerupType));
                this.powerupActivator.position.set(0, 0);
                if (!silent) {
                    this.game.sound.play('powerup_appearing', 0.6);
                    this.powerupActivator.scale.set(2.4);
                    this.game.add.tween(this.powerupActivator.scale)
                        .to({ x: 1, y: 1 }, 550, Phaser.Easing.Sinusoidal.In, true);
                }
            }
        };
        Ball.prototype.removePowerup = function () {
            if (this.powerupActivator) {
                this.powerupActivator.destroy();
                this.powerupActivator = null;
            }
            this.powerupType = null;
        };
        Ball.prototype.reachFinish = function () {
            this.ballManager.path.ballEaten();
            this.killBall();
        };
        Ball.prototype.explodeBall = function () {
            if (this.isAlive) {
                if (this.powerupActivator) {
                    this.powerupActivator.activate(this.ballManager.level.powerupManager);
                }
                if (this.visible) {
                    this.ballManager.level.effectsManager.addBallExplosion(this.ballManager, this.color, this.x, this.y);
                }
                this.ballManager.dispatchBallExploding(this);
                if (this.game.time.now - Ball.lastExplodedTimestamp > 50) {
                    this.game.sound.play('ball_destroying', 0.3);
                    Ball.lastExplodedTimestamp = this.game.time.now;
                }
                this.killBall();
            }
        };
        Ball.prototype.killBall = function () {
            if (!this.isAlive) {
                return;
            }
            this.isAlive = false;
            if (this.getPrev()) {
                this.getPrev().setNext(this.getNext());
            }
            if (this.getNext()) {
                this.getNext().setPrev(this.getPrev());
            }
            this.setPrev(null);
            this.setNext(null);
            this.ballManager.level.cannonManager.cannon.dispatchBallDestroying();
            this.destroy();
        };
        /**
         * Getters & Setters
         */
        Ball.prototype.getPrev = function () {
            return this._prev;
        };
        Ball.prototype.setPrev = function (ball) {
            this._prev = ball;
        };
        Ball.prototype.getNext = function () {
            return this._next;
        };
        Ball.prototype.setNext = function (ball) {
            this._next = ball;
        };
        Object.defineProperty(Ball.prototype, "backwardSpeed", {
            get: function () {
                return this._backwardSpeed;
            },
            set: function (value) {
                this._backwardSpeed = value < 0 ? value : 0;
            },
            enumerable: true,
            configurable: true
        });
        /**
         * DESTROY
         */
        Ball.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.path = null;
            this.pathPoint = null;
            this.ballManager = null;
            this.powerupActivator = null;
            this.view = null;
        };
        Ball.ID = 0;
        Ball.lastExplodedTimestamp = 0;
        return Ball;
    }(Phaser.Group));
    src.Ball = Ball;
})(src || (src = {}));
var src;
(function (src) {
    var BallColor;
    (function (BallColor) {
        BallColor[BallColor["BLACK"] = 0] = "BLACK";
        BallColor[BallColor["BLUE"] = 1] = "BLUE";
        BallColor[BallColor["GRAY"] = 2] = "GRAY";
        BallColor[BallColor["GREEN"] = 3] = "GREEN";
        BallColor[BallColor["PURPLE"] = 4] = "PURPLE";
        BallColor[BallColor["CYAN"] = 5] = "CYAN";
        BallColor[BallColor["YELLOW"] = 6] = "YELLOW";
        BallColor[BallColor["RED"] = 7] = "RED";
    })(BallColor = src.BallColor || (src.BallColor = {}));
})(src || (src = {}));
var src;
(function (src) {
    var BallSequence = (function () {
        function BallSequence(ballManager) {
            this.isAcceleratingBackward = false;
            this.ballManager = ballManager;
            this.balls = [];
        }
        BallSequence.prototype.push = function (ball, position) {
            if (position === void 0) { position = -1; }
            if (position == -1) {
                this.balls.push(ball);
            }
            else {
                this.balls.splice(position, 0, ball);
            }
        };
        BallSequence.prototype.getFirst = function () {
            return this.balls[0];
        };
        BallSequence.prototype.getLast = function () {
            return this.balls[this.balls.length - 1];
        };
        BallSequence.prototype.move = function (speed) {
            if (speed > 0) {
                this.moveForward(speed);
            }
            else if (speed < 0) {
                this.moveBackward(speed);
            }
        };
        BallSequence.prototype.update = function (isLightingRewindActive, sequenceIndex) {
            var backwardSpeed = this.getLast().backwardSpeed;
            if (this.isAcceleratingBackward) {
                backwardSpeed = (backwardSpeed > src.Settings.game.GAP_COLLAPSING_STARTING_SPEED * (isLightingRewindActive ? 2 : 1) ? src.Settings.game.GAP_COLLAPSING_STARTING_SPEED * (isLightingRewindActive ? 2 : 1) : backwardSpeed) * src.Settings.game.GAP_COLLAPSING_ACCELERATION_MULTIPLIER;
            }
            else {
                backwardSpeed = (backwardSpeed > src.Settings.game.GAP_COLLAPSING_STARTING_SPEED / 5 ? 0 : backwardSpeed) / src.Settings.game.GAP_COLLAPSING_ACCELERATION_MULTIPLIER;
            }
            backwardSpeed = backwardSpeed < -src.Settings.game.GAP_COLLAPSING_MAX_SPEED ? -src.Settings.game.GAP_COLLAPSING_MAX_SPEED : backwardSpeed;
            if (backwardSpeed < 0) {
                this.move(backwardSpeed);
                if (this.getFirst().getPrev() && this.getFirst().getPrev().isTouching(this.getFirst())) {
                    backwardSpeed *= isLightingRewindActive ? src.Settings.game.GAP_COLLAPSING_HIT_SLOWDOWN_FACTOR * 0.5 : src.Settings.game.GAP_COLLAPSING_HIT_SLOWDOWN_FACTOR;
                    if (sequenceIndex == 1 && !isLightingRewindActive) {
                        this.ballManager.path.speedManager.setChainSpeed(6, true);
                    }
                }
            }
            this.balls.forEach(function (ball) { return ball.backwardSpeed = backwardSpeed; });
        };
        BallSequence.prototype.moveForward = function (speed) {
            var ball = this.getFirst();
            ball.stepForward(speed);
            while (ball) {
                if (ball.getNext() && this.balls.indexOf(ball.getNext()) > -1) {
                    this.pushForward(ball, ball.getNext());
                }
                ball = ball.getNext();
            }
        };
        BallSequence.prototype.moveBackward = function (speed) {
            var ball = this.getFirst();
            var nextBall = ball.getNext();
            ball.stepBackward(speed);
            while (ball && !ball.isAlive) {
                if (!ball.isAlive) {
                    this.ballManager.ballFactory.pushToQueue(ball.color, ball.powerupType);
                }
                ball = nextBall;
                nextBall = (ball && ball.getNext() && this.balls.indexOf(ball.getNext()) > -1) ? ball.getNext() : null;
                if (ball) {
                    ball.stepBackward(speed);
                }
            }
            while (ball && ball.getNext() && this.balls.indexOf(ball.getNext()) > -1 && ball.getNext().onTheWay) {
                this.pullBackward(ball, ball.getNext());
                ball = ball.getNext();
            }
            if (this.getFirst().getPrev() && this.getFirst().getPrev().isTouching(this.getFirst())) {
                src.App.instance.sound.play('gap_collapsing', 0.7);
            }
        };
        BallSequence.prototype.pushForward = function (ballA, ballB) {
            if (!ballB.onTheWay) {
                return;
            }
            var nextPosition = ballA.getNextRelativePosition();
            ballB.updatePosition(ballA.onTheWay ? nextPosition : Math.max(nextPosition, ballB.getRelativePosition()));
        };
        BallSequence.prototype.pullBackward = function (ballA, ballB) {
            this.pushForward(ballA, ballB);
        };
        BallSequence.prototype.destroy = function () {
            this.ballManager = null;
            this.balls = null;
        };
        return BallSequence;
    }());
    src.BallSequence = BallSequence;
})(src || (src = {}));
var src;
(function (src) {
    var FreeBall = (function (_super) {
        __extends(FreeBall, _super);
        function FreeBall(cannonManager, color, x, y) {
            var _this = _super.call(this, src.App.instance) || this;
            _this.color = null;
            _this.speedX = 0;
            _this.speedY = 0;
            _this.isAlive = true;
            _this.isStarted = false;
            _this.cannonManager = cannonManager;
            _this.color = color;
            _this.position.set(x, y);
            _this.createContent();
            return _this;
        }
        FreeBall.prototype.createContent = function () {
            this.view = this.add(new src.AnimatedBallView(null, this.color));
        };
        FreeBall.prototype.isTouching = function (anotherBall) {
            return Phaser.Math.distance(this.x, this.y, anotherBall.x, anotherBall.y) <= src.Settings.BALL_DIAMETER;
        };
        FreeBall.prototype.changeColor = function (newColor) {
            this.color = newColor;
            if (this.view) {
                this.view.destroy();
            }
            this.createContent();
        };
        FreeBall.prototype.start = function (speedX, speedY) {
            if (this.parent) {
                this.parent.removeChild(this);
            }
            this.game.tweens.removeFrom(this, (this instanceof Phaser.Group) ? false : true);
            this.game.tweens.removeFrom(this.scale);
            this.cannonManager.add(this);
            var basePosition = this.position.clone();
            var rotationFactor = basePosition.rotate(0, 0, this.cannonManager.cannon.rotation);
            this.position.set(this.cannonManager.cannon.x + rotationFactor.x, this.cannonManager.cannon.y + rotationFactor.y);
            this.scale.set(1);
            this.isStarted = true;
            this.startPosition = this.position.clone();
            this.previousPosition = this.position.clone();
            this.speedX = speedX;
            this.speedY = speedY;
            if (this.cannonManager.level.powerupManager.hasAlivePowerups(src.PowerupType.LASER)) {
                this.speedX *= src.Settings.game.LASER_FREE_BALL_SPEED_MULTIPLIER;
                this.speedY *= src.Settings.game.LASER_FREE_BALL_SPEED_MULTIPLIER;
            }
            if (this instanceof src.FireBall) {
                this.cannonManager.level.powerupManager.add(this);
                this.speedX = this.speedX * src.Settings.game.FIREBALL_SPEED_MULTIPLIER;
                this.speedY = this.speedY * src.Settings.game.FIREBALL_SPEED_MULTIPLIER;
            }
            this.view.dispatchStart(speedX, speedY);
        };
        FreeBall.prototype.update = function () {
            _super.prototype.update.call(this);
            if (this.isStarted) {
                this.previousPosition.copyFrom(this.position);
                this.x += this.speedX * (src.Settings.REALTIME_CALCULATIONS ? this.game.time.elapsedMS / 1000 : this.game.time.physicsElapsed);
                this.y += this.speedY * (src.Settings.REALTIME_CALCULATIONS ? this.game.time.elapsedMS / 1000 : this.game.time.physicsElapsed);
                if (this.outOfScreen()) {
                    this.killBall();
                }
            }
        };
        FreeBall.prototype.killBall = function () {
            this.isAlive = false;
            this.destroy();
        };
        /**
         * PRIVATE
         */
        FreeBall.prototype.outOfScreen = function () {
            return (this.x < -src.Settings.BALL_DIAMETER / 2 || this.x > src.Settings.BALL_DIAMETER / 2 + src.CustomScaleManager.ORIGINAL_WIDTH || this.y < -src.Settings.BALL_DIAMETER / 2 || this.y > src.Settings.BALL_DIAMETER / 2 + src.CustomScaleManager.ORIGINAL_HEIGHT);
        };
        /**
         * DESTROY
         */
        FreeBall.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.cannonManager = null;
            this.view = null;
            this.startPosition = null;
        };
        return FreeBall;
    }(Phaser.Group));
    src.FreeBall = FreeBall;
})(src || (src = {}));
///<reference path="FreeBall.ts"/>
var src;
(function (src) {
    var FireBall = (function (_super) {
        __extends(FireBall, _super);
        function FireBall(cannonManager, x, y) {
            return _super.call(this, cannonManager, null, x, y) || this;
        }
        FireBall.prototype.createContent = function () {
            this.view = this.add(new src.FireBallView());
        };
        FireBall.prototype.update = function () {
            _super.prototype.update.call(this);
            if (this.view && this.parent && this.parent.parent && this.parent.parent instanceof src.Cannon) {
                this.view.rotation = -this.parent.parent.rotation;
            }
        };
        return FireBall;
    }(src.FreeBall));
    src.FireBall = FireBall;
})(src || (src = {}));
var src;
(function (src) {
    var OncomingBall = (function () {
        function OncomingBall(color, powerup) {
            this.powerup = null;
            this.color = color;
            this.powerup = powerup;
        }
        return OncomingBall;
    }());
    src.OncomingBall = OncomingBall;
})(src || (src = {}));
var src;
(function (src) {
    var BallContactResolver = (function () {
        function BallContactResolver(ballManager) {
            this.ballManager = ballManager;
        }
        BallContactResolver.prototype.update = function () {
            if (!this.ballManager.hasAliveBalls()) {
                return;
            }
            var pathSpeed = this.ballManager.path.speedManager.getChainSpeed();
            this.resolveFlyingBalls();
            this.resolveOverlaps();
            this.resolveSequences(pathSpeed);
        };
        BallContactResolver.prototype.resolveFlyingBalls = function () {
            var oncomingBalls = this.ballManager.getOncomingBalls();
            for (var _i = 0, oncomingBalls_1 = oncomingBalls; _i < oncomingBalls_1.length; _i++) {
                var ball = oncomingBalls_1[_i];
                if (ball.getPrev() && ball.isTouching(ball.getPrev())) {
                    ball.updatePosition(this.ballManager.path.calculateRelativePosition(ball.getPrev().getRelativePosition(), src.Settings.BALL_DIAMETER));
                }
                else if (ball.getNext() && ball.isTouching(ball.getNext())) {
                    ball.updatePosition(ball.getNext().getPrevRelativePosition());
                }
                else {
                    ball.updatePosition(ball.getRelativePosition());
                }
            }
        };
        BallContactResolver.prototype.resolveOverlaps = function () {
            var ball = this.ballManager.getFirstBall();
            while (ball && ball.getNext()) {
                if (ball.getNext().onTheWay && (ball.isTouching(ball.getNext()) || ball.getRelativePosition() > ball.getNext().getRelativePosition())) {
                    if (ball.onTheWay) {
                        ball.getNext().updatePosition(ball.getNextRelativePosition());
                    }
                    else {
                        ball.getNext().updatePosition(ball.getPrev() ? Math.max(ball.getPrev().getNextRelativePosition(), ball.getNextRelativePosition(), ball.getNext().getRelativePosition()) : Math.max(ball.getNextRelativePosition(), ball.getNext().getRelativePosition()));
                    }
                }
                ball = ball.getNext();
            }
        };
        BallContactResolver.prototype.resolveSequences = function (pathSpeed) {
            var sequences = this.ballManager.getSequences();
            if (pathSpeed < 0) {
                sequences[sequences.length - 1].move(pathSpeed);
            }
            else {
                sequences[0].move(pathSpeed);
                this.manageGaps(sequences);
            }
            if (sequences.length == 1) {
                this.ballManager.path.speedManager.hasLightingPowerupActivated = false;
            }
            //sequences.forEach(sequence => sequence.balls.forEach(ball => App.instance.debug.text('' + sequences.indexOf(sequence), ball.x, ball.y, "#FFFFFF", "25px Verdana")));
            //sequences.forEach(sequence => sequence.balls.forEach(ball => App.instance.debug.text('' + Math.floor(ball.backwardSpeed), ball.x, ball.y + 10, "#FF0000", "15px Verdana")));
            sequences.forEach(function (sequence) { return sequence.destroy(); });
        };
        BallContactResolver.prototype.manageGaps = function (sequences) {
            //find and mark active gaps
            var firstGapFound = false;
            for (var i = sequences.length - 1; i > 0; i--) {
                var sequence = sequences[i];
                var prevSequence = sequences[i - 1];
                if (sequence.getFirst().onTheWay && prevSequence.getLast().onTheWay) {
                    if (!firstGapFound && (sequence.getFirst().color == prevSequence.getLast().color)) {
                        firstGapFound = true;
                        sequence.isAcceleratingBackward = true;
                    }
                    else if (this.ballManager.path.speedManager.hasLightingPowerupActivated) {
                        sequence.isAcceleratingBackward = true;
                    }
                }
            }
            //update sequences
            for (var i = sequences.length - 1; i > -1; i--) {
                sequences[i].update(this.ballManager.path.speedManager.hasLightingPowerupActivated, i);
            }
        };
        BallContactResolver.prototype.destroy = function () {
            this.ballManager = null;
        };
        return BallContactResolver;
    }());
    src.BallContactResolver = BallContactResolver;
})(src || (src = {}));
var src;
(function (src) {
    var BallFactory = (function () {
        function BallFactory(ballManager) {
            this.countdown = 1000;
            this.totalBalls = 0;
            this.ballManager = ballManager;
        }
        BallFactory.getRandomColor = function () {
            return Phaser.ArrayUtils.getRandomItem([
                src.BallColor.BLUE,
                src.BallColor.GRAY,
                src.BallColor.GREEN,
                src.BallColor.PURPLE,
                src.BallColor.CYAN,
                src.BallColor.YELLOW,
                src.BallColor.RED
            ]);
        };
        /**
         * PUBLIC METHODS
         */
        BallFactory.prototype.createQueue = function (balls) {
            this.ballsQueue = [];
            for (var i = 0; i < balls.length; i++) {
                this.ballsQueue.push(new src.OncomingBall(balls[i], null));
            }
            //shuffle queue
            var spliceIndex = Math.floor(Math.random() * this.ballsQueue.length);
            this.ballsQueue = this.ballsQueue.concat(this.ballsQueue.splice(0, spliceIndex));
            this.totalBalls = this.ballsQueue.length;
        };
        BallFactory.prototype.clearQueue = function (targetCapacity) {
            if (targetCapacity === void 0) { targetCapacity = 0; }
            if (this.ballsQueue.length > targetCapacity) {
                this.ballsQueue.splice(targetCapacity);
            }
        };
        BallFactory.prototype.pushToQueue = function (color, powerupType) {
            this.ballsQueue.push(new src.OncomingBall(color, powerupType));
        };
        BallFactory.prototype.update = function () {
            if (!this.ballManager.path.isStarted) {
                return;
            }
            if (this.countdown > 0) {
                this.countdown -= src.App.instance.time.elapsedMS;
                return;
            }
            if (this.ballManager.path.speedManager.getChainSpeed() >= 0) {
                while (this.ballsQueue.length > 0 && this.hasEmptyPlaceForABall()) {
                    this.insertBallFromQueue();
                }
            }
        };
        BallFactory.prototype.insertBallBefore = function (path, targetBall, color, x, y, startPosition) {
            var prevBall = targetBall.getPrev();
            var ball = new src.Ball(this.ballManager, path, color, targetBall.getPrevRelativePosition(), this.ballManager.level.cannonManager, startPosition);
            ball.onTheWay = false;
            ball.position.set(x, y);
            ball.insertionSpeedMultiplier = 0.75;
            targetBall.setPrev(ball);
            ball.setNext(targetBall);
            if (prevBall) {
                ball.setPrev(prevBall);
                prevBall.setNext(ball);
                this.ballManager.balls.splice(this.ballManager.balls.indexOf(targetBall), 0, ball);
            }
            else {
                this.ballManager.balls.unshift(ball);
            }
            this.ballManager.level.cannonManager.cannon.dispatchBallCreating();
            this.ballManager.game.sound.play('ball_inserting', 0.25);
            return ball;
        };
        BallFactory.prototype.insertBallAfter = function (path, targetBall, color, x, y, startPosition) {
            var nextBall = targetBall.getNext();
            var nextRelativePosition = nextBall ? nextBall.getRelativePosition() : targetBall.getNextRelativePosition();
            if (nextRelativePosition == -1) {
                // console.log("BallFactory::insertBallAfter - can't insert new ball in the end of the chain, seems like end of the chain is reached");
                return null;
            }
            var ball = new src.Ball(this.ballManager, path, color, nextRelativePosition, this.ballManager.level.cannonManager, startPosition);
            ball.onTheWay = false;
            ball.position.set(x, y);
            targetBall.setNext(ball);
            ball.setPrev(targetBall);
            if (nextBall) {
                ball.setNext(nextBall);
                nextBall.setPrev(ball);
                this.ballManager.balls.splice(this.ballManager.balls.indexOf(nextBall), 0, ball);
            }
            else {
                this.ballManager.balls.push(ball);
            }
            this.ballManager.level.cannonManager.cannon.dispatchBallCreating();
            this.ballManager.game.sound.play('ball_inserting', 0.25);
            return ball;
        };
        /**
         * PRIVATE
         */
        BallFactory.prototype.hasEmptyPlaceForABall = function () {
            if (!this.ballManager.hasAliveBalls()) {
                return true;
            }
            return this.ballManager.getFirstBall().pathPoint.chainIndex >= 1;
        };
        BallFactory.prototype.insertBallFromQueue = function () {
            if (this.ballsQueue.length > 0) {
                var firstBall = this.ballManager.getFirstBall();
                var position = 0;
                if (firstBall) {
                    position = (firstBall.getPrevRelativePosition() >= 0 && firstBall.getPrevRelativePosition() <= 1) ? firstBall.getPrevRelativePosition() : 0;
                }
                var ballProperties = this.ballsQueue.pop();
                var ball = new src.Ball(this.ballManager, this.ballManager.path, ballProperties.color, position);
                if (ballProperties.powerup) {
                    ball.createPowerup(ballProperties.powerup, true);
                }
                if (firstBall) {
                    ball.setNext(firstBall);
                    firstBall.setPrev(ball);
                }
                this.ballManager.level.cannonManager.cannon.dispatchBallCreating();
                this.ballManager.balls.unshift(ball);
            }
        };
        /**
         * DESTROY
         */
        BallFactory.prototype.destroy = function () {
            this.ballManager = null;
        };
        return BallFactory;
    }());
    src.BallFactory = BallFactory;
})(src || (src = {}));
var src;
(function (src) {
    var BallRenderer = (function (_super) {
        __extends(BallRenderer, _super);
        function BallRenderer(ballManager) {
            var _this = _super.call(this, ballManager.game, null) || this;
            _this.ballManager = ballManager;
            return _this;
        }
        BallRenderer.prototype.render = function () {
            for (var _i = 0, _a = this.ballManager.balls; _i < _a.length; _i++) {
                var ball = _a[_i];
                if (ball.isAlive && ball.visible) {
                }
            }
        };
        return BallRenderer;
    }(Phaser.Group));
    src.BallRenderer = BallRenderer;
})(src || (src = {}));
var src;
(function (src) {
    var BallView = (function (_super) {
        __extends(BallView, _super);
        function BallView() {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.isStarted = false;
            return _this;
        }
        BallView.prototype.dispatchStart = function (speedX, speedY) {
            this.isStarted = true;
        };
        return BallView;
    }(Phaser.Group));
    src.BallView = BallView;
})(src || (src = {}));
///<reference path="BallView.ts"/>
var src;
(function (src) {
    var AnimatedBallView = (function (_super) {
        __extends(AnimatedBallView, _super);
        function AnimatedBallView(ball, color) {
            var _this = _super.call(this) || this;
            _this.textureSpeed = 0;
            _this.ballFrame = 0;
            _this.ball = ball;
            _this.color = color;
            _this.createContent();
            return _this;
        }
        AnimatedBallView.prototype.createContent = function () {
            this.ballBackground = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'ball' + this.color + '0000'));
            this.ballBackground.anchor.set(0.5);
            this.rollingAnimation = this.ballBackground.animations.add('rollingAnimation', AnimatedBallView.ballAnimations[this.color], 60, true);
            this.rollingAnimation.play();
            this.rollingAnimation.stop();
            this.cover = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'ballCover' + '0000'));
            this.cover.anchor.set(0.5);
        };
        AnimatedBallView.prototype.move = function (dx, dy) {
            this.textureSpeed = Phaser.Math.distance(0, 0, dx, dy);
            if (this.ball && this.ball.isAlive && this.ball.previousPosition > this.ball.getRelativePosition()) {
                this.ballFrame -= this.textureSpeed;
                while (Math.round(this.ballFrame) < 0) {
                    this.ballFrame += 44;
                }
            }
            else {
                this.ballFrame += this.textureSpeed;
                while (Math.round(this.ballFrame) > 43) {
                    this.ballFrame -= 44;
                }
            }
            this.rollingAnimation.frame = Math.round(this.ballFrame);
        };
        AnimatedBallView.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.color = null;
            this.cover = null;
            this.ballBackground = null;
            this.ball = null;
            this.rollingAnimation = null;
        };
        AnimatedBallView.ballAnimations = [
            Phaser.Animation.generateFrameNames('ball0', 0, 43, '', 4),
            Phaser.Animation.generateFrameNames('ball1', 0, 43, '', 4),
            Phaser.Animation.generateFrameNames('ball2', 0, 43, '', 4),
            Phaser.Animation.generateFrameNames('ball3', 0, 43, '', 4),
            Phaser.Animation.generateFrameNames('ball4', 0, 43, '', 4),
            Phaser.Animation.generateFrameNames('ball5', 0, 43, '', 4),
            Phaser.Animation.generateFrameNames('ball6', 0, 43, '', 4),
            Phaser.Animation.generateFrameNames('ball7', 0, 43, '', 4),
        ];
        return AnimatedBallView;
    }(src.BallView));
    src.AnimatedBallView = AnimatedBallView;
})(src || (src = {}));
///<reference path="BallView.ts"/>
var src;
(function (src) {
    var FireBallView = (function (_super) {
        __extends(FireBallView, _super);
        function FireBallView() {
            var _this = _super.call(this) || this;
            _this.createContent();
            return _this;
        }
        FireBallView.prototype.createContent = function () {
            this.ball = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'fireBall' + '0000'));
            this.ball.anchor.set(0.5);
            this.fireAnimation = this.ball.animations.add('fireBall', Phaser.Animation.generateFrameNames('fireBall', 0, 15, '', 4));
            this.fireAnimation.play(60, true);
            this.tail = this.addAt(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, null), 0);
            this.tail.anchor.set(0.5, 0.1);
            this.tail.visible = false;
            this.tailAnimation = this.tail.animations.add('fireBallTail', Phaser.Animation.generateFrameNames('fireBallTail', 0, 19, '', 4));
        };
        FireBallView.prototype.move = function (dx, dy) {
        };
        FireBallView.prototype.dispatchStart = function (startX, startY) {
            _super.prototype.dispatchStart.call(this, startX, startY);
            this.rotation = 0;
            this.tail.visible = true;
            this.tailAnimation.play(120, true);
            this.tail.rotation = Phaser.Math.angleBetween(0, 0, startX, startY) + Math.PI / 2;
        };
        FireBallView.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.ball = null;
            this.fireAnimation = null;
        };
        return FireBallView;
    }(src.BallView));
    src.FireBallView = FireBallView;
})(src || (src = {}));
var src;
(function (src) {
    var Cannon = (function (_super) {
        __extends(Cannon, _super);
        function Cannon(cannonManager, platform) {
            var _this = _super.call(this, src.App.instance) || this;
            _this.activeBall = null;
            _this.nextBall = null;
            _this.lastColors = [];
            _this.cooldown = 0;
            _this.isReady = false;
            _this.cannonManager = cannonManager;
            _this.commonContainer = _this.add(_this.game.make.group(null));
            _this.platform = platform;
            _this.position.copyFrom(_this.platform.position);
            _this.buildGraphics();
            return _this;
        }
        /**
         * PUBLIC METHODS
         */
        Cannon.prototype.start = function () {
            this.generateBalls();
            this.isReady = true;
        };
        Cannon.prototype.update = function () {
            _super.prototype.update.call(this);
            if (this.cooldown > 0) {
                this.cooldown -= this.game.time.elapsedMS;
                this.isReady = false;
            }
            else {
                this.isReady = true;
            }
        };
        Cannon.prototype.rotateToPointer = function (pointerPosition) {
            this.rotation = Phaser.Math.angleBetween(this.x, this.y, pointerPosition.x, pointerPosition.y) + Math.PI / 2;
        };
        Cannon.prototype.isPointerOver = function (pointerPosition) {
            return Phaser.Math.distance(pointerPosition.x, pointerPosition.y, this.x, this.y) < src.Settings.CANNON_TOUCH_ZONE_DIAMETER / 2;
        };
        Cannon.prototype.shoot = function () {
            if (this.activeBall) {
                this.rotateToPointer(this.cannonManager.level.getInputPosition());
                if (this.activeBall instanceof src.FireBall) {
                    this.game.sound.play('shot0' + (1 + Math.floor(Math.random() * 2)), 0.5);
                    this.game.sound.play('fireball_shot', 0.6);
                    this.shootBall(new src.FireBall(this.cannonManager, src.Settings.ACTIVE_BALL_POSITION.x, src.Settings.ACTIVE_BALL_POSITION.y), -Phaser.Math.degToRad(src.Settings.game.FIREBALL_ANGLE));
                    this.shootBall(new src.FireBall(this.cannonManager, src.Settings.ACTIVE_BALL_POSITION.x, src.Settings.ACTIVE_BALL_POSITION.y), Phaser.Math.degToRad(src.Settings.game.FIREBALL_ANGLE));
                }
                this.shootBall(this.activeBall);
                this.game.sound.play('shot0' + (1 + Math.floor(Math.random() * 2)), 0.3);
                src.TutorialManager.instance.dispatchShoot(this.cannonManager.level.getInputPosition().clone());
                this.cooldown = this.cannonManager.level.powerupManager.hasAlivePowerups(src.PowerupType.LASER) ? src.Settings.game.ZOOMER_COOLDOWN / 2 : src.Settings.game.ZOOMER_COOLDOWN;
                this.activeBall = this.nextBall;
                this.game.add.tween(this.activeBall)
                    .to({
                    x: src.Settings.ACTIVE_BALL_POSITION.x,
                    y: src.Settings.ACTIVE_BALL_POSITION.y
                }, 200, Phaser.Easing.Cubic.Out, true);
                this.game.add.tween(this.activeBall.scale)
                    .to({ x: 1, y: 1 }, 300, Phaser.Easing.Back.Out, true);
                this.nextBall = this.ballsContainer.add(new src.FreeBall(this.cannonManager, this.getNextColor(), src.Settings.NEXT_BALL_POSITION.x, src.Settings.NEXT_BALL_POSITION.y));
                this.nextBall.scale.set(0.01);
                this.game.add.tween(this.nextBall.scale)
                    .to({
                    x: src.Settings.NEXT_BALL_SCALE,
                    y: src.Settings.NEXT_BALL_SCALE
                }, 100, Phaser.Easing.Linear.None, true);
                this.ballsContainer.bringToTop(this.activeBall);
                this.playRecoilAnimation();
            }
        };
        Cannon.prototype.swapBalls = function () {
            if (this.activeBall && this.nextBall) {
                src.TutorialManager.instance.dispatchBallsSwap(this);
                src.SoundController.instance.playSwapSound();
                _a = [this.nextBall, this.activeBall], this.activeBall = _a[0], this.nextBall = _a[1];
                this.game.add.tween(this.activeBall)
                    .to({
                    x: src.Settings.ACTIVE_BALL_POSITION.x,
                    y: src.Settings.ACTIVE_BALL_POSITION.y
                }, 180, Phaser.Easing.Quintic.InOut, true);
                this.game.add.tween(this.activeBall.scale)
                    .to({ x: 1, y: 1 }, 180, Phaser.Easing.Quintic.InOut, true);
                this.game.add.tween(this.nextBall)
                    .to({
                    x: src.Settings.NEXT_BALL_POSITION.x,
                    y: src.Settings.NEXT_BALL_POSITION.y
                }, 180, Phaser.Easing.Quintic.InOut, true);
                this.game.add.tween(this.nextBall.scale)
                    .to({
                    x: src.Settings.NEXT_BALL_SCALE,
                    y: src.Settings.NEXT_BALL_SCALE
                }, 180, Phaser.Easing.Quintic.InOut, true);
            }
            var _a;
        };
        Cannon.prototype.jumpToPlatform = function (platform) {
            var _this = this;
            if (platform != this.platform) {
                src.TutorialManager.instance.dispatchPlatformChange(platform);
                this.game.tweens.removeFrom(platform.platformBorder.scale);
                platform.platformBorder.scale.set(0.85);
                this.platform = platform;
                this.game.sound.play('platform_change', 0.6);
                this.game.add.tween(this.scale)
                    .to({ x: 0.6, y: 0.6 }, 80, Phaser.Easing.Sinusoidal.In, true)
                    .onComplete.add(function () { return _this.game.add.tween(_this.scale)
                    .to({ x: 1, y: 1 }, 80, Phaser.Easing.Sinusoidal.Out, true)
                    .onStart.add(function () {
                    _this.position.copyFrom(_this.platform.position);
                }); });
                this.game.add.tween(this)
                    .to({ alpha: 0 }, 80, Phaser.Easing.Sinusoidal.In, true)
                    .onComplete.add(function () { return _this.game.add.tween(_this)
                    .to({ alpha: 1 }, 80, Phaser.Easing.Sinusoidal.Out, true); });
            }
        };
        Cannon.prototype.activateFireBall = function () {
            if (this.activeBall) {
                this.activeBall.destroy();
                this.activeBall = null;
            }
            this.activeBall = this.ballsContainer.add(new src.FireBall(this.cannonManager, src.Settings.ACTIVE_BALL_POSITION.x, src.Settings.ACTIVE_BALL_POSITION.y));
            this.activeBall.scale.set(0.1);
            this.game.add.tween(this.activeBall.scale)
                .to({ x: 1, y: 1 }, 180, Phaser.Easing.Quintic.InOut, true);
            this.addFireballAppearingEffect(this.activeBall);
            this.game.sound.play('fireball_picking_up', 0.7);
        };
        Cannon.prototype.dispatchBallDestroying = function () {
            if (this.cannonManager.level.gameStateManager.hasLosingPaths) {
                return;
            }
            var availableColors = this.cannonManager.level.pathManager.getAvailableColorsArray();
            if (availableColors.length == 0) {
                this.cannonManager.level.coinManager.hideAllCoins();
                this.destroyBalls();
                return;
            }
            if (!(this.activeBall instanceof src.FireBall) && availableColors.indexOf(this.activeBall.color) == -1) {
                this.activeBall.changeColor(this.cannonManager.getNextColor(null));
            }
            if (!(this.nextBall instanceof src.FireBall) && availableColors.indexOf(this.nextBall.color) == -1) {
                this.nextBall.changeColor(this.cannonManager.getNextColor(null));
            }
        };
        Cannon.prototype.dispatchBallCreating = function () {
            this.generateBalls();
        };
        /**
         * PRIVATE METHODS
         */
        Cannon.prototype.buildGraphics = function () {
            this.bottomSprite = this.commonContainer.add(this.game.make.sprite(2, -52, src.Settings.GAME_ATLAS, 'cannonBot' + '0000'));
            this.bottomSprite.anchor.set(0.5, 0.5);
            this.ballsContainer = this.commonContainer.add(this.game.make.group());
            this.ballsContainer.inputEnableChildren = false;
            this.topSprite = this.commonContainer.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'cannonTop' + '0000'));
            this.topSprite.anchor.set(0.5, 0.5);
        };
        Cannon.prototype.addFireballAppearingEffect = function (freeBall) {
            var sprite = freeBall.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS));
            sprite.anchor.set(0.5);
            sprite.scale.set(0.65);
            sprite.animations.add('bombExplosion', Phaser.Animation.generateFrameNames('bombExplosion', 0, 17, '', 4));
            sprite.animations.play('bombExplosion', 60, false, true);
        };
        Cannon.prototype.playRecoilAnimation = function () {
            var _this = this;
            this.commonContainer.y = 0;
            this.game.tweens.removeFrom(this.commonContainer);
            this.game.add.tween(this.commonContainer)
                .to({ y: src.Settings.game.ZOOMER_RECOIL }, src.Settings.game.ZOOMER_RECOIL_DURATION, Phaser.Easing.Linear.None, true)
                .onComplete.add(function () {
                _this.game.add.tween(_this.commonContainer)
                    .to({ y: 0 }, src.Settings.game.ZOOMER_RECOIL_DURATION, Phaser.Easing.Linear.None, true);
            });
        };
        Cannon.prototype.generateBalls = function () {
            if (!this.activeBall || !this.nextBall) {
                this.ballsContainer.removeAll(true);
                this.activeBall = this.ballsContainer.add(new src.FreeBall(this.cannonManager, this.cannonManager.getFirstColor(), src.Settings.ACTIVE_BALL_POSITION.x, src.Settings.ACTIVE_BALL_POSITION.y));
                this.activeBall.scale.set(0);
                this.game.add.tween(this.activeBall.scale)
                    .to({ x: 1, y: 1 }, 300, Phaser.Easing.Back.Out, true);
                this.nextBall = this.ballsContainer.add(new src.FreeBall(this.cannonManager, this.getNextColor(), src.Settings.NEXT_BALL_POSITION.x, src.Settings.NEXT_BALL_POSITION.y));
                this.nextBall.scale.set(0);
                this.game.add.tween(this.nextBall.scale)
                    .to({
                    x: src.Settings.NEXT_BALL_SCALE,
                    y: src.Settings.NEXT_BALL_SCALE
                }, 300, Phaser.Easing.Linear.None, true);
            }
        };
        Cannon.prototype.getNextColor = function () {
            var nextColor = this.cannonManager.getNextColor(this.lastColors.length >= src.Settings.game.ZOOMER_MAX_SAME_COLOR_BALLS_SEQUENCE ? this.lastColors[0] : null);
            if (this.lastColors.length > 0 && this.lastColors[this.lastColors.length - 1] != nextColor) {
                this.lastColors.splice(0, this.lastColors.length);
            }
            this.lastColors.push(nextColor);
            return nextColor;
        };
        Cannon.prototype.destroyBalls = function () {
            if (this.activeBall) {
                this.cannonManager.level.effectsManager.addBallExplosion(this.ballsContainer, this.activeBall.color, this.activeBall.x, this.activeBall.y);
                this.activeBall.destroy();
            }
            if (this.nextBall) {
                this.cannonManager.level.effectsManager.addBallExplosion(this.ballsContainer, this.nextBall.color, this.nextBall.x, this.nextBall.y).scale.copyFrom(this.nextBall.scale);
                this.nextBall.destroy();
            }
            this.activeBall = null;
            this.nextBall = null;
        };
        Cannon.prototype.shootBall = function (ball, deltaAngle) {
            if (deltaAngle === void 0) { deltaAngle = 0; }
            this.cannonManager.balls.push(ball);
            ball.position.set(src.Settings.ACTIVE_BALL_POSITION.x, src.Settings.ACTIVE_BALL_POSITION.y);
            ball.start(Math.sin(this.rotation + deltaAngle) * src.Settings.game.FREE_BALL_SPEED, -Math.cos(this.rotation + deltaAngle) * src.Settings.game.FREE_BALL_SPEED);
        };
        /**
         * DESTROY METHOD
         */
        Cannon.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.activeBall = null;
            this.nextBall = null;
            this.cannonManager = null;
            this.platform = null;
        };
        return Cannon;
    }(Phaser.Group));
    src.Cannon = Cannon;
})(src || (src = {}));
var src;
(function (src) {
    var Platform = (function (_super) {
        __extends(Platform, _super);
        function Platform(cannonManager, x, y) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.cannonManager = cannonManager;
            _this.position.set(x, y);
            _this.platformBackground = _this.add(_this.game.make.sprite(-1, 1.5, src.Settings.GAME_ATLAS, 'platformBackground' + '0000'));
            _this.platformBackground.anchor.set(0.5);
            _this.platformBorder = _this.add(_this.game.make.sprite(-2, -2, src.Settings.GAME_ATLAS, 'platformBorder' + '0000'));
            _this.platformBorder.anchor.set(0.5);
            _this.platformBorder.scale.set(0.85);
            _this.platform = _this.add(_this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'platform' + '0000'));
            _this.platform.anchor.set(0.5);
            return _this;
        }
        Platform.prototype.handleTap = function (inputPosition) {
            if (Phaser.Math.distance(this.x, this.y, inputPosition.x, inputPosition.y) < src.Settings.PLATFORM_TOUCH_ZONE_DIAMETER / 2) {
                if (this.cannonManager.cannon && this.cannonManager.cannon.platform != this) {
                    return true;
                }
            }
            return false;
        };
        Platform.prototype.highlight = function () {
            this.platformBorder.rotation = 0;
            var appearingTween = this.game.add.tween(this.platformBorder.scale)
                .to({ x: 1, y: 1 }, 300, Phaser.Easing.Linear.None, true);
            var disappearingTween = this.game.add.tween(this.platformBorder.scale)
                .to({ x: 0.85, y: 0.85 }, 300, Phaser.Easing.Linear.None, false, src.Settings.PLATFORM_ROTATION_TIME);
            appearingTween.chain(disappearingTween);
        };
        Platform.prototype.update = function () {
            _super.prototype.update.call(this);
            if (this.platformBorder.scale.x > 0.85) {
                this.platformBorder.rotation += src.Settings.PLATFORM_ROTATION_SPEED * this.game.time.elapsedMS / 1000;
            }
        };
        Platform.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.onChildInputDown.removeAll();
            this.cannonManager = null;
        };
        return Platform;
    }(Phaser.Group));
    src.Platform = Platform;
})(src || (src = {}));
var src;
(function (src) {
    var Coin = (function (_super) {
        __extends(Coin, _super);
        function Coin(coinManager, coinPlace) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.lifetime = src.Settings.game.COIN_LIFETIME;
            _this.isAlive = true;
            _this.coinManager = coinManager;
            _this.coinPlace = coinPlace;
            _this.x = coinPlace.x;
            _this.y = coinPlace.y;
            _this.coinPlace.setCoin(_this);
            _this.buildSprites();
            _this.startTweens();
            return _this;
        }
        Coin.prototype.update = function () {
            _super.prototype.update.call(this);
            this.lifetime -= this.game.time.elapsedMS;
            if (this.lifetime < 1000 && this.lifetime > 0) {
                this.alpha = this.lifetime / 1000;
            }
            if (this.lifetime < 0) {
                this.destroy();
            }
        };
        Coin.prototype.buildSprites = function () {
            this.coinShadow = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'coinShadow' + '0000'));
            this.coinShadow.anchor.set(0.5);
            this.coin = this.add(this.game.make.sprite(0, -35, src.Settings.GAME_ATLAS));
            this.coin.anchor.set(0.5);
            this.coinAnimation = this.coin.animations.add('coinRotation', Phaser.Animation.generateFrameNames('coin', 0, 27, '', 4));
            this.coinAnimation.play(60, true);
        };
        Coin.prototype.startTweens = function () {
            this.scale.set(0.1);
            this.game.add.tween(this.scale)
                .to({ x: 1, y: 1 }, 250, Phaser.Easing.Back.Out, true);
        };
        Coin.prototype.isTouching = function (ball) {
            return Phaser.Math.distance(this.x, this.y - 35, ball.x, ball.y) <= src.Settings.BALL_DIAMETER * 0.8;
        };
        Coin.prototype.pickupCoin = function () {
            src.StatsManager.instance.addCoin();
            this.coinManager.level.effectsManager.addCoinExplosion(this.x, this.y);
            this.destroy();
        };
        Coin.prototype.destroy = function () {
            if (!this.isAlive) {
                return;
            }
            this.isAlive = false;
            _super.prototype.destroy.call(this);
            this.coinPlace.removeCoin();
            this.coinPlace = null;
            this.coinManager = null;
            this.coin = null;
            this.coinShadow = null;
            this.coinAnimation = null;
        };
        return Coin;
    }(Phaser.Group));
    src.Coin = Coin;
})(src || (src = {}));
var src;
(function (src) {
    var CoinPlace = (function () {
        function CoinPlace(x, y) {
            this.coin = null;
            this.x = x;
            this.y = y;
        }
        CoinPlace.prototype.setCoin = function (coin) {
            this.coin = coin;
        };
        CoinPlace.prototype.removeCoin = function () {
            if (this.coin) {
                this.coin = null;
            }
        };
        return CoinPlace;
    }());
    src.CoinPlace = CoinPlace;
})(src || (src = {}));
var src;
(function (src) {
    var Daemon = (function (_super) {
        __extends(Daemon, _super);
        function Daemon(daemonManager, path, x, y, rotation) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.state = src.DaemonState.CLOSED;
            _this.daemonManager = daemonManager;
            _this.path = path;
            _this.position.set(x, y);
            _this.rotation = rotation;
            _this.buildSprites();
            _this.buildAnimations();
            return _this;
        }
        Daemon.prototype.buildSprites = function () {
            this.daemonBot = this.daemonManager.level.backgroundManager.add(this.game.make.sprite(this.x, this.y, src.Settings.GAME_ATLAS, 'daemonBot' + '0000'));
            this.daemonBot.anchor.set(0.5, 0.5);
            this.daemonBot.rotation = this.rotation;
            this.daemonLowerTeeth = this.daemonManager.level.wayManager.add(this.game.make.sprite(this.x, this.y, src.Settings.GAME_ATLAS, 'daemonLowerTeeth' + '0000'));
            this.daemonLowerTeeth.anchor.set(0.52, 0.12);
            this.daemonLowerTeeth.rotation = this.rotation;
            this.daemonUpperTeeth = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'daemonUpperTeeth' + '0000'));
            this.daemonUpperTeeth.anchor.set(0.525, 0.66);
            this.daemonLight = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'daemonLight' + '0000'));
            this.daemonLight.anchor.set(0.5, 0.9);
            this.daemonTop = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'daemonTop' + '0000'));
            this.daemonTop.anchor.set(0.5, 0.755);
            this.daemonEyeLeft = this.add(this.game.make.sprite(-28, 0, src.Settings.GAME_ATLAS, 'daemonEye' + '0000'));
            this.daemonEyeLeft.anchor.set(0.5, 1.15);
            this.daemonEyeRight = this.add(this.game.make.sprite(24.5, 0, src.Settings.GAME_ATLAS, 'daemonEye' + '0000'));
            this.daemonEyeRight.anchor.set(0.5, 1.16);
            this.daemonEyeRight.scale.set(-1, 1);
        };
        Daemon.prototype.buildAnimations = function () {
            var _this = this;
            this.leftEyeOpeningAnimation = this.daemonEyeLeft.animations.add('leftEyeOpeningAnimation', Phaser.Animation.generateFrameNames('daemonEye', 0, 45, '', 4), 60, false);
            this.leftEyeClosingAnimation = this.daemonEyeLeft.animations.add('leftEyeClosingAnimation', Phaser.Animation.generateFrameNames('daemonEye', 0, 45, '', 4).reverse(), 60, false);
            this.rightEyeOpeningAnimation = this.daemonEyeRight.animations.add('rightEyeOpeningAnimation', Phaser.Animation.generateFrameNames('daemonEye', 0, 45, '', 4), 60, false);
            this.rightEyeClosingAnimation = this.daemonEyeRight.animations.add('rightEyeClosingAnimation', Phaser.Animation.generateFrameNames('daemonEye', 0, 45, '', 4).reverse(), 60, false);
            this.lightOpeningAnimation = this.daemonLight.animations.add('lightOpeningAnimation', Phaser.Animation.generateFrameNames('daemonLight', 0, 31, '', 4), 60, false);
            this.lightClosingAnimation = this.daemonLight.animations.add('lightClosingAnimation', Phaser.Animation.generateFrameNames('daemonLight', 0, 31, '', 4).reverse(), 60, false);
            this.upperTeethOpeningAnimation = this.daemonUpperTeeth.animations.add('upperTeethOpeningAnimation', Phaser.Animation.generateFrameNames('daemonUpperTeeth', 0, 34, '', 4), 60, false);
            this.upperTeethClosingAnimation = this.daemonUpperTeeth.animations.add('upperTeethClosingAnimation', Phaser.Animation.generateFrameNames('daemonUpperTeeth', 0, 34, '', 4).reverse(), 60, false);
            this.lowerTeethOpeningAnimation = this.daemonLowerTeeth.animations.add('lowerTeethOpeningAnimation', Phaser.Animation.generateFrameNames('daemonLowerTeeth', 0, 32, '', 4), 60, false);
            this.lowerTeethClosingAnimation = this.daemonLowerTeeth.animations.add('lowerTeethClosingAnimation', Phaser.Animation.generateFrameNames('daemonLowerTeeth', 0, 32, '', 4).reverse(), 60, false);
            this.lowerTeethOpeningAnimation.onStart.add(function () { return _this.state = src.DaemonState.OPENING; });
            this.lowerTeethOpeningAnimation.onComplete.add(function () { return _this.state = src.DaemonState.OPENED; });
            this.lowerTeethClosingAnimation.onStart.add(function () { return _this.state = src.DaemonState.CLOSING; });
            this.lowerTeethClosingAnimation.onComplete.add(function () { return _this.state = src.DaemonState.CLOSED; });
        };
        Daemon.prototype.openMouth = function (playSound) {
            if (playSound === void 0) { playSound = true; }
            this.lightOpeningAnimation.play();
            this.upperTeethOpeningAnimation.play();
            this.lowerTeethOpeningAnimation.play();
            this.leftEyeOpeningAnimation.play();
            this.rightEyeOpeningAnimation.play();
            if (playSound) {
                this.game.sound.play('idol_mouth_opening', 0.5);
            }
        };
        Daemon.prototype.closeMouth = function (playSound) {
            if (playSound === void 0) { playSound = true; }
            this.lightClosingAnimation.play();
            this.upperTeethClosingAnimation.play();
            this.lowerTeethClosingAnimation.play();
            this.leftEyeClosingAnimation.play();
            this.rightEyeClosingAnimation.play();
            if (playSound) {
                this.game.sound.play('idol_mouth_closing', 0.4);
            }
        };
        Daemon.prototype.update = function () {
            _super.prototype.update.call(this);
            var aliveBalls = this.path.ballManager.getAliveBallsCount();
            if (this.state == src.DaemonState.OPENED || this.state == src.DaemonState.OPENING) {
                if (aliveBalls > 0
                    && this.path.ballManager.getFirstBall().getRelativePosition() >= this.path.pathPoints.length - 2) {
                    //all the balls has been eaten
                    this.closeMouth();
                }
                else if (aliveBalls > 0
                    && Phaser.Math.distance(this.path.ballManager.getLastBall().x, this.path.ballManager.getLastBall().y, this.x, this.y) > src.Settings.game.getBallSpeed()
                    && this.path.ballManager.getLastBall().getRelativePosition() < this.path.calculateRelativePosition(this.path.pathPoints.length - 2, -src.Settings.game.getBallSpeed())) {
                    // the last ball hasn't reached daemon's mouth yet
                    this.closeMouth();
                }
                else if (this.path.isStarted && aliveBalls == 0) {
                    //close mouth if there is no balls on the path
                    this.closeMouth();
                }
            }
            if (this.state == src.DaemonState.CLOSED || this.state == src.DaemonState.CLOSING) {
                if (!this.path.isStarted) {
                    //the path is not ready tet
                    this.openMouth(false);
                }
                else if (aliveBalls > 0
                    && this.path.ballManager.getFirstBall().getRelativePosition() < this.path.pathPoints.length - 2
                    && Phaser.Math.distance(this.path.ballManager.getLastBall().x, this.path.ballManager.getLastBall().y, this.x, this.y) < src.Settings.game.getBallSpeed()
                    && this.path.ballManager.getLastBall().getRelativePosition() >= this.path.calculateRelativePosition(this.path.pathPoints.length - 2, -src.Settings.game.getBallSpeed())) {
                    //balls are very close to the mouth
                    this.openMouth();
                }
            }
        };
        Daemon.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.daemonBot.destroy();
            this.daemonLowerTeeth.destroy();
            this.daemonManager = null;
            this.path = null;
            this.daemonEyeLeft = null;
            this.daemonEyeRight = null;
            this.daemonLowerTeeth = null;
            this.daemonUpperTeeth = null;
            this.daemonLight = null;
            this.daemonTop = null;
            this.daemonBot = null;
            this.leftEyeOpeningAnimation = null;
            this.leftEyeClosingAnimation = null;
            this.rightEyeOpeningAnimation = null;
            this.rightEyeClosingAnimation = null;
            this.lightOpeningAnimation = null;
            this.lightClosingAnimation = null;
            this.upperTeethOpeningAnimation = null;
            this.upperTeethClosingAnimation = null;
            this.lowerTeethOpeningAnimation = null;
            this.lowerTeethClosingAnimation = null;
        };
        return Daemon;
    }(Phaser.Group));
    src.Daemon = Daemon;
})(src || (src = {}));
var src;
(function (src) {
    var DaemonState;
    (function (DaemonState) {
        DaemonState[DaemonState["CLOSING"] = 1] = "CLOSING";
        DaemonState[DaemonState["CLOSED"] = 2] = "CLOSED";
        DaemonState[DaemonState["OPENING"] = 3] = "OPENING";
        DaemonState[DaemonState["OPENED"] = 4] = "OPENED";
    })(DaemonState = src.DaemonState || (src.DaemonState = {}));
})(src || (src = {}));
var src;
(function (src) {
    var PathPoint = (function (_super) {
        __extends(PathPoint, _super);
        function PathPoint(parentGroup, x, y, chainIndex, radius, color) {
            if (chainIndex === void 0) { chainIndex = 0; }
            if (radius === void 0) { radius = 5; }
            if (color === void 0) { color = 0x000000; }
            var _this = _super.call(this, src.App.instance, x, y) || this;
            _this.prev = null;
            _this.next = null;
            _this.startPosition = 0;
            _this.pathLength = 0;
            _this.chainIndex = 0;
            _this.parentGroup = parentGroup;
            _this.radius = radius;
            _this.color = color;
            _this.chainIndex = chainIndex;
            _this.drawContent();
            return _this;
        }
        PathPoint.prototype.drawContent = function () {
            this.clear();
            this.beginFill(this.color, 1);
            this.drawCircle(0, 0, this.radius);
            this.endFill();
        };
        PathPoint.prototype.drawPath = function () {
            this.lineStyle(1, this.color, 0.7).moveTo(0, 0).lineTo(this.next.x - this.x, this.next.y - this.y);
        };
        PathPoint.prototype.calculateLength = function () {
            this.pathLength = Phaser.Math.distance(this.x, this.y, this.next.x, this.next.y);
            this.next.startPosition = this.startPosition + this.pathLength;
        };
        PathPoint.prototype.setPrev = function (prev) {
            this.prev = prev;
        };
        PathPoint.prototype.setNext = function (next) {
            this.next = next;
            if (this.next) {
                this.calculateLength();
                this.drawPath();
            }
        };
        /**
         * Destroy method
         */
        PathPoint.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.prev = null;
            this.next = null;
            this.parentGroup = null;
        };
        return PathPoint;
    }(Phaser.Graphics));
    src.PathPoint = PathPoint;
})(src || (src = {}));
///<reference path="PathPoint.ts"/>
var src;
(function (src) {
    var KeyPoint = (function (_super) {
        __extends(KeyPoint, _super);
        function KeyPoint(parentGroup, x, y, radius, color) {
            if (radius === void 0) { radius = 15; }
            if (color === void 0) { color = 0xFF0000; }
            return _super.call(this, parentGroup, x, y, 0, radius, color) || this;
        }
        return KeyPoint;
    }(src.PathPoint));
    src.KeyPoint = KeyPoint;
})(src || (src = {}));
var src;
(function (src) {
    var Path = (function (_super) {
        __extends(Path, _super);
        function Path(pathManager) {
            var _this = _super.call(this, pathManager.game) || this;
            _this.totalLength = 0;
            _this.warningPosition = 0;
            _this.hasEatenBalls = false;
            _this.isStarted = false;
            _this.isCleared = false;
            _this.isFinished = false;
            _this.isLost = false;
            _this.pathManager = pathManager;
            _this.pathInitializer = _this.add(new src.PathInitializer(_this));
            _this.pathFinalizer = _this.add(new src.PathFinalizer(_this));
            _this.ballManager = _this.add(new src.BallManager(_this));
            _this.tunnelManager = _this.add(new src.TunnelManager(_this));
            _this.speedManager = new src.PathSpeedManager(_this);
            return _this;
        }
        /**
         * BUILDERS
         */
        Path.prototype.construct = function (keyPointsArray, tension, resolution, balls) {
            this.buildPathPoints(keyPointsArray, tension, resolution);
            this.ballManager.initQueue(balls);
            this.totalLength = this.getEndPoint().startPosition;
            this.warningPosition = this.totalLength - src.Settings.game.SLOWDOWN_POINT_BALLS_COUNT * src.Settings.BALL_DIAMETER;
            this.tunnelManager.buildTunnels();
        };
        Path.prototype.start = function () {
            this.isStarted = true;
            this.speedManager.start();
            this.daemon.closeMouth();
        };
        Path.prototype.pathCleared = function () {
            this.pathManager.pathCleared(this);
        };
        Path.prototype.ballEaten = function () {
            var _this = this;
            if (!this.hasEatenBalls) {
                this.hasEatenBalls = true;
                this.ballManager.ballFactory.clearQueue(10);
                this.game.time.events.add(1300, function () { return _this.pathManager.dispatchPathLose(_this); });
            }
        };
        Path.prototype.lose = function () {
            if (!this.isLost) {
                this.isLost = true;
                this.pathManager.dispatchPathLose(this);
            }
        };
        Path.prototype.getStartPoint = function () {
            return (this.pathPoints.length > 0) ? this.pathPoints[0] : null;
        };
        Path.prototype.getEndPoint = function () {
            return (this.pathPoints.length > 0) ? this.pathPoints[this.pathPoints.length - 1] : null;
        };
        Path.prototype.getTotalLength = function () {
            return this.pathPoints.length > 0 ? this.pathPoints.length - 0.0000001 : 0;
        };
        Path.prototype.getPathPoint = function (relativePosition) {
            return (relativePosition >= 0 && this.pathPoints.length > ~~relativePosition) ? this.pathPoints[~~relativePosition] : null;
        };
        Path.prototype.isUnderground = function (relativePosition) {
            if (relativePosition >= this.pathPoints.length - 2) {
                return true;
            }
            for (var _i = 0, _a = this.tunnelManager.tunnels; _i < _a.length; _i++) {
                var tunnel = _a[_i];
                if (relativePosition >= tunnel.entrancePosition && relativePosition <= tunnel.exitPosition) {
                    return true;
                }
            }
            return false;
        };
        Path.prototype.isVisible = function (relativePosition) {
            for (var _i = 0, _a = this.tunnelManager.tunnels; _i < _a.length; _i++) {
                var tunnel = _a[_i];
                if (relativePosition >= tunnel.startPosition && relativePosition <= tunnel.endPosition) {
                    return false;
                }
            }
            return true;
        };
        Path.prototype.getConcretePosition = function (relativePosition) {
            if (this.pathPoints.length == 0 || relativePosition < 0 || this.pathPoints.length <= relativePosition) {
                return null;
            }
            var pathPoint = this.pathPoints[~~relativePosition];
            if (pathPoint) {
                return pathPoint.next ? src.AdvancedMath.pointOnSegmentRelative(pathPoint.x, pathPoint.y, pathPoint.next.x, pathPoint.next.y, src.AdvancedMath.getDecimal(relativePosition)) : pathPoint.position.clone();
            }
            return null;
        };
        Path.prototype.calculateRelativePosition = function (relativePosition, shift) {
            var pathPoint = this.getPathPoint(relativePosition);
            var segmentProgress = src.AdvancedMath.getDecimal(relativePosition) * pathPoint.pathLength;
            if (shift >= 0) {
                while (pathPoint && segmentProgress + shift >= pathPoint.pathLength) {
                    shift -= (pathPoint.pathLength - segmentProgress);
                    segmentProgress = 0;
                    pathPoint = pathPoint.next;
                }
                if (pathPoint) {
                    segmentProgress += shift;
                    return pathPoint.chainIndex + (pathPoint.pathLength > 0 ? (segmentProgress / pathPoint.pathLength) : 0);
                }
                else {
                    return -1;
                }
            }
            else {
                var frameDistance = Math.abs(shift);
                while (pathPoint && segmentProgress - frameDistance < 0) {
                    frameDistance -= segmentProgress;
                    pathPoint = pathPoint.prev;
                    if (pathPoint) {
                        segmentProgress = pathPoint.pathLength;
                    }
                }
                if (pathPoint) {
                    segmentProgress -= frameDistance;
                    return pathPoint.chainIndex + (pathPoint.pathLength > 0 ? (segmentProgress / pathPoint.pathLength) : 0);
                }
                else {
                    return -1;
                }
            }
        };
        /**
         * UPDATE HANDLER
         */
        Path.prototype.update = function () {
            this.speedManager.update();
            _super.prototype.update.call(this);
            if (this.hasEatenBalls && !this.isLost && this.ballManager.getAliveBallsCount() == 0 && this.ballManager.getFutureBallsCount() == 0) {
                this.lose();
            }
        };
        /**
         * PRIVATE METHODS
         */
        Path.prototype.buildPathPoints = function (keyPointsArray, tension, resolution) {
            var pathPointPairs = src.PathBuilder.generatePathPointsArray(keyPointsArray, tension, resolution);
            this.pathPoints = [];
            if (pathPointPairs.length < 2) {
                console.log("Path is too short!");
            }
            else {
                //add base pathpoint
                var basePathPoint = src.AdvancedMath.pointOnSegment(pathPointPairs[0][0], pathPointPairs[0][1], pathPointPairs[1][0], pathPointPairs[1][1], -src.Settings.BALL_DIAMETER);
                pathPointPairs.unshift([basePathPoint.x, basePathPoint.y]);
                //add end pathpoint
                var endPathPoint = src.AdvancedMath.pointOnSegment(pathPointPairs[pathPointPairs.length - 1][0], pathPointPairs[pathPointPairs.length - 1][1], pathPointPairs[pathPointPairs.length - 2][0], pathPointPairs[pathPointPairs.length - 2][1], -1.2 * src.Settings.BALL_DIAMETER);
                pathPointPairs.push([endPathPoint.x, endPathPoint.y]);
            }
            for (var i = 0; i < pathPointPairs.length; i++) {
                var pathPoint = new src.PathPoint(this, pathPointPairs[i][0], pathPointPairs[i][1], i, 5, 0x000099);
                if (i > 0) {
                    this.pathPoints[this.pathPoints.length - 1].setNext(pathPoint);
                    pathPoint.setPrev(this.pathPoints[this.pathPoints.length - 1]);
                }
                this.pathPoints.push(pathPoint);
            }
        };
        Path.prototype.clearPathPoints = function () {
            if (this.pathPoints) {
                this.pathPoints.forEach(function (pathPoint) { return pathPoint.destroy(); });
            }
            this.pathPoints = [];
        };
        /**
         * DESTROY METHOD
         */
        Path.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.speedManager.destroy();
            this.speedManager = null;
            this.pathInitializer = null;
            this.pathFinalizer = null;
            this.pathManager = null;
            this.tunnelManager = null;
        };
        return Path;
    }(Phaser.Group));
    src.Path = Path;
})(src || (src = {}));
var src;
(function (src) {
    var PathFinalizer = (function (_super) {
        __extends(PathFinalizer, _super);
        function PathFinalizer(path) {
            var _this = _super.call(this, path.game, null) || this;
            _this.startPosition = 0;
            _this.bonusPoints = 0;
            _this.path = path;
            return _this;
        }
        PathFinalizer.prototype.start = function () {
            var lastPosition = this.path.calculateRelativePosition(this.path.getTotalLength(), -2 * src.Settings.BALL_DIAMETER);
            var concretePosition = this.path.getConcretePosition(this.startPosition);
            var position = this.path.calculateRelativePosition(this.startPosition, src.Settings.game.PATH_FINISHED_BONUS_STEP);
            var delay = src.Settings.game.PATH_FINISHED_BONUS_DELAY;
            while (position < lastPosition && position >= 0) {
                var newConcretePosition = this.path.getConcretePosition(position);
                src.StatsManager.instance.addBonus(1);
                src.ScoreManager.instance.displayScores(src.Settings.game.PATH_FINISHED_BONUS_SCORE, true, src.BallFactory.getRandomColor(), newConcretePosition.x, newConcretePosition.y, delay, false, false, Phaser.Math.random(0.6, 0.8), true);
                delay += src.Settings.game.PATH_FINISHED_BONUS_DELAY;
                position = this.path.calculateRelativePosition(position, src.Settings.game.PATH_FINISHED_BONUS_STEP);
                concretePosition = newConcretePosition;
                this.bonusPoints++;
            }
            this.game.time.events.add(delay + 300, this.finishPath, this);
        };
        PathFinalizer.prototype.setStartposition = function (relativePosition) {
            this.startPosition = relativePosition;
        };
        PathFinalizer.prototype.finishPath = function () {
            this.path.isFinished = true;
            this.path.pathManager.finalizeNext(this.path);
        };
        PathFinalizer.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.path = null;
        };
        return PathFinalizer;
    }(Phaser.Group));
    src.PathFinalizer = PathFinalizer;
})(src || (src = {}));
var src;
(function (src) {
    var PathInitializer = (function (_super) {
        __extends(PathInitializer, _super);
        function PathInitializer(path) {
            var _this = _super.call(this, path.game, null) || this;
            _this.path = path;
            return _this;
        }
        PathInitializer.prototype.start = function () {
            var _this = this;
            var lastPosition = this.path.calculateRelativePosition(this.path.getTotalLength(), -src.Settings.BALL_DIAMETER);
            var concretePosition = this.path.getConcretePosition(0);
            var position = this.path.calculateRelativePosition(0, src.Settings.game.PATH_ARROW_STEP);
            var speed = this.path.totalLength / src.Settings.game.PATH_ARROW_DURATION;
            var delay = src.Settings.game.PATH_ARROW_BASE_DELAY;
            while (position < lastPosition && position >= 0) {
                var newConcretePosition = this.path.getConcretePosition(position);
                if (this.path.isVisible(position)) {
                    var rotation = Phaser.Math.angleBetween(concretePosition.x, concretePosition.y, newConcretePosition.x, newConcretePosition.y) + Math.PI / 2;
                    this.add(new src.PathArrow(newConcretePosition.x, newConcretePosition.y, rotation, delay));
                }
                delay += src.Settings.game.PATH_ARROW_STEP / speed;
                position = this.path.calculateRelativePosition(position, src.Settings.game.PATH_ARROW_STEP);
                concretePosition = newConcretePosition;
            }
            this.game.time.events.add(src.Settings.game.PATH_ARROW_BASE_DELAY, function () { return _this.game.sound.play('path_initialization', 0.8); });
            this.game.time.events.add(delay + 250, this.activatePath, this);
        };
        PathInitializer.prototype.activatePath = function () {
            this.path.pathManager.initializeNext(this.path);
        };
        PathInitializer.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.path = null;
        };
        return PathInitializer;
    }(Phaser.Group));
    src.PathInitializer = PathInitializer;
})(src || (src = {}));
var src;
(function (src) {
    var PathSpeedManager = (function () {
        function PathSpeedManager(path) {
            this.isRewindActive = false;
            this.hasLightingPowerupActivated = false;
            this.targetSpeed = src.Settings.game.CHAIN_START_SPEED;
            this.speed = src.Settings.game.CHAIN_START_SPEED;
            this.useExpotentialAcceleration = true;
            this.rewindCountdown = 0;
            this.isStartingSpeedupActive = true;
            this.isWarningPointReached = false;
            this.hasActiveSlowdownPowerup = false;
            this.hasBallsInTheQueue = false;
            this.hasBallsOnThePath = false;
            this.hasEatenBalls = false;
            this.path = path;
            this.level = path.pathManager.level;
            this.ballManager = path.ballManager;
            this.rollingBallsSound = this.path.game.add.sound('rolling_balls', 1, true);
        }
        PathSpeedManager.prototype.start = function () {
            this.rollingBallsSound.play();
        };
        PathSpeedManager.prototype.update = function () {
            this.checkConditions();
            this.updateTargetSpeed();
            this.updateChainSpeed();
            if (src.Settings.ENABLE_DEBUG_OUTPUT) {
                this.level.game.debug.text('' + Phaser.Math.roundTo(this.getChainSpeed(), -1), 580, 14, "#70f0ff");
            }
        };
        PathSpeedManager.prototype.checkConditions = function () {
            var lastMovingBall = this.ballManager.getLastMovingBall();
            var lastBallPosition = lastMovingBall ? lastMovingBall.getAbsolutePosition() : -1;
            this.rewindCountdown -= (src.Settings.REALTIME_CALCULATIONS ? this.level.game.time.elapsedMS : this.level.game.time.physicsElapsedMS);
            this.hasBallsInTheQueue = this.ballManager.ballFactory.ballsQueue.length > 0;
            this.hasBallsOnThePath = this.ballManager.getAliveBallsCount() > 0;
            this.hasEatenBalls = this.path.hasEatenBalls;
            this.isWarningPointReached = lastBallPosition > this.path.warningPosition;
            this.hasActiveSlowdownPowerup = this.level.powerupManager.hasAlivePowerups(src.PowerupType.SLOWDOWN);
            this.isRewindActive = this.hasEatenBalls ? false : this.isRewindActive && this.rewindCountdown > 0;
            this.isStartingSpeedupActive = this.isStartingSpeedupActive && lastBallPosition < this.path.totalLength * src.Settings.game.getChainQuickFillInPercentage();
            if (this.isRewindActive && !this.hasBallsOnThePath) {
                this.isRewindActive = false;
                this.speed = 0;
            }
        };
        PathSpeedManager.prototype.updateTargetSpeed = function () {
            if (this.isWarningPointReached) {
                this.targetSpeed = src.Settings.game.getBallSpeed() * src.Settings.game.SLOWDOWN_POINT_SPEED_MULTIPLIER;
            }
            else {
                if (this.isStartingSpeedupActive) {
                    var lastBallPosition = this.ballManager.getLastMovingBall() ? this.ballManager.getLastMovingBall().getAbsolutePosition() : -1;
                    var normalSpeedPosition = this.path.totalLength * src.Settings.game.getChainQuickFillInPercentage();
                    if (normalSpeedPosition - lastBallPosition < src.Settings.game.CHAIN_QUICK_FILL_IN_BREAKING_ABSOLUTE_DISTANCE) {
                        this.speed = this.targetSpeed = src.Settings.game.getBallSpeed() + (normalSpeedPosition - lastBallPosition) / src.Settings.game.CHAIN_QUICK_FILL_IN_BREAKING_ABSOLUTE_DISTANCE * (src.Settings.game.CHAIN_START_SPEED - src.Settings.game.getBallSpeed());
                    }
                    else {
                        this.targetSpeed = src.Settings.game.CHAIN_START_SPEED;
                    }
                }
                else {
                    this.targetSpeed = src.Settings.game.getBallSpeed();
                }
            }
            if (this.hasActiveSlowdownPowerup) {
                this.targetSpeed *= this.level.powerupManager.getAlivePowerup(src.PowerupType.SLOWDOWN).slowdownMultiplier;
            }
            if (this.isRewindActive) {
                this.targetSpeed = src.Settings.game.REWIND_SPEED;
            }
        };
        PathSpeedManager.prototype.updateChainSpeed = function () {
            if (this.hasEatenBalls) {
                var ballsLeft = this.ballManager.balls.length + this.ballManager.ballFactory.ballsQueue.length;
                this.speed = this.targetSpeed = src.Settings.game.CHAIN_LOSE_SPEED * (1 + src.Settings.game.CHAIN_LOSE_ACCELERATION_MULTIPLIER * (ballsLeft / this.ballManager.ballFactory.totalBalls));
                this.rollingBallsSound.volume = Phaser.Math.clamp(this.hasBallsOnThePath ? Math.abs(this.speed) / 850 : 0, 0, 1);
                return;
            }
            if (this.speed < this.targetSpeed) {
                if (this.useExpotentialAcceleration && Phaser.Math.sign(this.speed) == Phaser.Math.sign(this.targetSpeed)) {
                    this.speed *= src.Settings.game.PATH_EXPOTENTIAL_ACCELERATION;
                }
                else {
                    this.speed += src.Settings.game.PATH_ACCELERATION;
                }
                if (this.speed > this.targetSpeed) {
                    this.speed = this.targetSpeed;
                    this.useExpotentialAcceleration = false;
                }
            }
            else if (this.speed > this.targetSpeed) {
                if (this.useExpotentialAcceleration && Phaser.Math.sign(this.speed) == Phaser.Math.sign(this.targetSpeed)) {
                    this.speed /= src.Settings.game.PATH_EXPOTENTIAL_ACCELERATION;
                }
                else {
                    this.speed -= src.Settings.game.PATH_ACCELERATION;
                }
                if (this.speed < this.targetSpeed) {
                    this.speed = this.targetSpeed;
                    this.useExpotentialAcceleration = false;
                }
            }
            this.rollingBallsSound.volume = Phaser.Math.clamp(this.hasBallsOnThePath ? Math.abs(this.speed) / 850 : 0, 0, 1);
        };
        PathSpeedManager.prototype.getChainSpeed = function () {
            return this.speed;
        };
        PathSpeedManager.prototype.setChainSpeed = function (speed, expotentialAcceleration) {
            if (expotentialAcceleration === void 0) { expotentialAcceleration = false; }
            this.speed = speed;
            this.useExpotentialAcceleration = expotentialAcceleration && !this.isRewindActive;
        };
        PathSpeedManager.prototype.activateRewind = function () {
            this.isRewindActive = true;
            this.useExpotentialAcceleration = false;
            this.rewindCountdown = src.Settings.game.REWIND_POWERUP_DURATION;
        };
        PathSpeedManager.prototype.pause = function () {
            this.rollingBallsSound.volume = 0;
        };
        PathSpeedManager.prototype.resume = function () {
        };
        PathSpeedManager.prototype.destroy = function () {
            this.rollingBallsSound.stop();
            this.rollingBallsSound.destroy();
            this.rollingBallsSound = null;
            this.path = null;
            this.level = null;
            this.ballManager = null;
        };
        return PathSpeedManager;
    }());
    src.PathSpeedManager = PathSpeedManager;
})(src || (src = {}));
var src;
(function (src) {
    var PathBuilder = (function (_super) {
        __extends(PathBuilder, _super);
        function PathBuilder() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        /**
         * STATIC
         */
        PathBuilder.generatePathPointsArray = function (keyPointsArray, tension, resolution) {
            var pathPointsArray = [];
            var keyPointsCoordinates = [];
            //convert keypoints
            for (var i = 0; i < keyPointsArray.length; i++) {
                keyPointsCoordinates.push(keyPointsArray[i][0]);
                keyPointsCoordinates.push(keyPointsArray[i][1]);
            }
            //generate new pathpoints based on keypoints
            var resultingPoints = src.Settings.USE_NEW_PATH_GENERATOR
                ? new src.CurveCalculator().getCurvePoints(keyPointsCoordinates, tension)
                : new src.CurveCalculator().getCurvePointsClassic(keyPointsCoordinates, tension, resolution);
            for (var i = 0; i < resultingPoints.length; i += 2) {
                pathPointsArray.push([resultingPoints[i], resultingPoints[i + 1]]);
            }
            return pathPointsArray;
        };
        return PathBuilder;
    }(Phaser.Group));
    src.PathBuilder = PathBuilder;
})(src || (src = {}));
var src;
(function (src) {
    var PowerupActivator = (function (_super) {
        __extends(PowerupActivator, _super);
        function PowerupActivator(ball, powerupType) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.lifetime = src.Settings.game.POWERUP_LIFETIME;
            _this.ball = ball;
            _this.ball.powerupType = powerupType;
            _this.powerupType = powerupType;
            _this.buildSprites();
            _this.buildAnimations();
            return _this;
        }
        PowerupActivator.prototype.buildSprites = function () {
            this.lightSprite = this.add(this.game.make.sprite(0, 0, src.Settings.GAME_ATLAS, 'powerupLight0000'));
            this.lightSprite.anchor.set(0.5);
            this.iconSprite = this.add(this.game.make.sprite(2, 2, src.Settings.GAME_ATLAS, 'powerupIcons' + '000' + this.powerupType));
            this.iconSprite.anchor.set(0.5);
        };
        PowerupActivator.prototype.buildAnimations = function () {
            var baseFrames = Phaser.Animation.generateFrameNames('powerupLight', 0, 22, '', 4);
            this.lightAnimation = this.lightSprite.animations.add('lightAnimation', baseFrames.concat(baseFrames.concat([]).reverse()), 60, true);
            this.lightAnimation.play();
        };
        PowerupActivator.prototype.activate = function (powerupManager) {
            if (powerupManager) {
                powerupManager.activatePowerup(this.powerupType, this.ball);
            }
        };
        PowerupActivator.prototype.update = function () {
            _super.prototype.update.call(this);
            this.lifetime -= this.game.time.elapsedMS;
            if (this.lifetime < 1000 && this.lifetime > 0) {
                this.alpha = this.lifetime / 1000;
            }
            if (this.lifetime < 0) {
                this.ball.removePowerup();
            }
        };
        PowerupActivator.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.ball = null;
        };
        return PowerupActivator;
    }(Phaser.Group));
    src.PowerupActivator = PowerupActivator;
})(src || (src = {}));
var src;
(function (src) {
    var PowerupEventType = (function () {
        function PowerupEventType() {
        }
        PowerupEventType.timer = function () {
            return 0;
        };
        PowerupEventType.combo = function (multiplier) {
            var index = 5;
            switch (multiplier) {
                case 2:
                    index = 5;
                    break;
                case 3:
                    index = 6;
                    break;
                case 4:
                    index = 7;
                    break;
                case 5:
                    index = 8;
                    break;
                case 6:
                    index = 9;
                    break;
            }
            return index;
        };
        PowerupEventType.gapBonus = function (multiplier) {
            var index = 1;
            switch (multiplier) {
                case 1:
                    index = 1;
                    break;
                case 2:
                    index = 2;
                    break;
                case 3:
                    index = 3;
                    break;
                case 4:
                case 5:
                case 6:
                case 7:
                case 8:
                    index = 4;
                    break;
            }
            return index;
        };
        return PowerupEventType;
    }());
    src.PowerupEventType = PowerupEventType;
})(src || (src = {}));
var src;
(function (src) {
    var PowerupType;
    (function (PowerupType) {
        PowerupType[PowerupType["SLOWDOWN"] = 0] = "SLOWDOWN";
        PowerupType[PowerupType["REWIND"] = 1] = "REWIND";
        PowerupType[PowerupType["BOMB"] = 2] = "BOMB";
        PowerupType[PowerupType["LIGHTING"] = 3] = "LIGHTING";
        PowerupType[PowerupType["LASER"] = 4] = "LASER";
        PowerupType[PowerupType["FIREBALL"] = 5] = "FIREBALL";
    })(PowerupType = src.PowerupType || (src.PowerupType = {}));
})(src || (src = {}));
var src;
(function (src) {
    var Powerup = (function (_super) {
        __extends(Powerup, _super);
        function Powerup(powerupManager, powerupType, isContinuous, duration, targetBall) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.duration = 0;
            _this.isContinuous = false;
            _this.isDead = false;
            _this.isActive = true;
            _this.powerupManager = powerupManager;
            _this.level = powerupManager.level;
            _this.targetBall = targetBall;
            _this.powerupType = powerupType;
            _this.isContinuous = isContinuous;
            _this.startingDuration = duration;
            _this.activate();
            return _this;
        }
        Powerup.prototype.activate = function () {
            this.duration = this.startingDuration;
            this.isActive = true;
        };
        Powerup.prototype.refresh = function (ball) {
            this.targetBall = ball;
            this.duration = this.startingDuration;
            this.isActive = true;
        };
        Powerup.prototype.update = function () {
            _super.prototype.update.call(this);
            this.duration -= this.game.time.elapsedMS;
            if (this.duration <= 0) {
                this.killPowerup();
            }
        };
        Powerup.prototype.killPowerup = function () {
            this.isDead = true;
            this.isActive = false;
            if (this.powerupManager.powerUps.indexOf(this) > -1) {
                this.powerupManager.powerUps.splice(this.powerupManager.powerUps.indexOf(this), 1);
            }
            this.destroy();
        };
        Powerup.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.powerupManager = null;
            this.level = null;
            this.targetBall = null;
        };
        return Powerup;
    }(Phaser.Group));
    src.Powerup = Powerup;
})(src || (src = {}));
///<reference path="Powerup.ts"/>
var src;
(function (src) {
    var BombPowerup = (function (_super) {
        __extends(BombPowerup, _super);
        function BombPowerup(powerupManager, targetBall) {
            return _super.call(this, powerupManager, src.PowerupType.BOMB, false, 0, targetBall) || this;
        }
        BombPowerup.prototype.activate = function () {
            _super.prototype.activate.call(this);
            this.destroyBallsAround(this.targetBall.x, this.targetBall.y);
            if (this.targetBall && this.targetBall.visible) {
                this.level.effectsManager.addBombExplosion(this.targetBall.x, this.targetBall.y);
                this.game.sound.play('bomb_explosion', 0.8);
                this.game.camera.shake(0.006, 350);
            }
        };
        BombPowerup.prototype.destroyBallsAround = function (x, y) {
            var woundedBalls = 0;
            for (var _i = 0, _a = this.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball && ball.isAlive && Phaser.Math.distance(x, y, ball.x, ball.y) <= src.Settings.game.BOMB_EXPLOSION_RADIUS) {
                        var accessible = (ball.path == this.targetBall.path);
                        accessible = accessible && (ball.path.calculateRelativePosition(ball.getRelativePosition(), src.Settings.game.BOMB_EXPLOSION_RADIUS) >= this.targetBall.getRelativePosition()
                            || ball.path.calculateRelativePosition(ball.getRelativePosition(), -src.Settings.game.BOMB_EXPLOSION_RADIUS) <= this.targetBall.getRelativePosition());
                        if (ball.visible || accessible) {
                            woundedBalls++;
                            this.game.time.events.add(src.Settings.game.BOMB_EXPLOSION_DELAY, function (ball) {
                                src.ScoreManager.instance.displayScores(src.ScoreManager.instance.calculateScores(1), true, ball.color, ball.x, ball.y, Phaser.Math.random(5, 200), true, true);
                                ball.explodeBall();
                            }, this, ball);
                        }
                    }
                }
            }
            if (woundedBalls > 0) {
                this.targetBall.ballManager.propagateImpulse(this.targetBall, 700);
            }
        };
        return BombPowerup;
    }(src.Powerup));
    src.BombPowerup = BombPowerup;
})(src || (src = {}));
var src;
(function (src) {
    var FireballPowerup = (function (_super) {
        __extends(FireballPowerup, _super);
        function FireballPowerup(powerupManager, targetBall) {
            return _super.call(this, powerupManager, src.PowerupType.FIREBALL, false, 0, targetBall) || this;
        }
        FireballPowerup.prototype.activate = function () {
            _super.prototype.activate.call(this);
            this.level.cannonManager.cannon.activateFireBall();
        };
        return FireballPowerup;
    }(src.Powerup));
    src.FireballPowerup = FireballPowerup;
})(src || (src = {}));
var src;
(function (src) {
    var LaserPowerup = (function (_super) {
        __extends(LaserPowerup, _super);
        function LaserPowerup(powerupManager, targetBall) {
            var _this = _super.call(this, powerupManager, src.PowerupType.LASER, true, src.Settings.game.LASER_POWERUP_DURATION, targetBall) || this;
            _this.laserEffect = _this.powerupManager.level.cannonManager.addAt(new src.LaserEffect(), 0);
            _this.laserHighlight = _this.add(_this.game.make.sprite(-100, -100, src.Settings.GAME_ATLAS, 'laserHighlight' + '0000'));
            _this.laserHighlight.anchor.set(0.5);
            _this.laserHighlight.visible = false;
            return _this;
        }
        LaserPowerup.prototype.activate = function () {
            _super.prototype.activate.call(this);
            this.game.sound.play('lazer', 0.4);
        };
        LaserPowerup.prototype.postUpdate = function () {
            _super.prototype.postUpdate.call(this);
            if (!this.isDead) {
                this.position.copyFrom(new Phaser.Point(this.powerupManager.level.cannonManager.cannon.x, this.powerupManager.level.cannonManager.cannon.y - 68).rotate(this.powerupManager.level.cannonManager.cannon.x, this.powerupManager.level.cannonManager.cannon.y, this.powerupManager.level.cannonManager.cannon.rotation));
                this.laserEffect.position.copyFrom(this.position);
                this.laserEffect.rotation = this.powerupManager.level.cannonManager.cannon.rotation;
                this.updateSprites();
                if (this.duration < 1500) {
                    this.alpha = (this.duration < 750 && Math.random() > 0.6) ? 0 : this.duration / 1500;
                }
                else {
                    this.alpha = 1;
                }
            }
        };
        LaserPowerup.prototype.updateSprites = function () {
            var closestBall = null;
            var closestDistance = Number.MAX_VALUE;
            var closestIntersectionPoint = null;
            var rayEnd = (new Phaser.Point(this.x, this.y - 1000)).rotate(this.x, this.y, this.laserEffect.rotation, false);
            for (var _i = 0, _a = this.powerupManager.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball && ball.isAlive && !ball.isUnderground) {
                        var targetPoint = src.AdvancedMath.findLineCircleIntersections(ball.x, ball.y, src.Settings.BALL_DIAMETER / 2, this.x, this.y, rayEnd.x, rayEnd.y, true);
                        if (targetPoint) {
                            var distance = Phaser.Math.distance(this.x, this.y, targetPoint.x, targetPoint.y);
                            if (distance < closestDistance) {
                                closestDistance = distance;
                                closestBall = ball;
                                closestIntersectionPoint = targetPoint;
                            }
                        }
                    }
                }
            }
            if (closestBall) {
                this.laserEffect.setLength(closestDistance);
                this.laserHighlight.visible = true;
                this.laserHighlight.position.set(closestBall.x - this.x, closestBall.y - this.y);
            }
            else {
                this.laserEffect.setLength(-1);
                this.laserHighlight.visible = false;
            }
        };
        LaserPowerup.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.laserEffect.destroy();
            this.laserEffect = null;
            this.laserHighlight.destroy();
            this.laserHighlight = null;
        };
        return LaserPowerup;
    }(src.Powerup));
    src.LaserPowerup = LaserPowerup;
})(src || (src = {}));
var src;
(function (src) {
    var LightingPowerup = (function (_super) {
        __extends(LightingPowerup, _super);
        function LightingPowerup(powerupManager, targetBall) {
            return _super.call(this, powerupManager, src.PowerupType.LIGHTING, true, 1000, targetBall) || this;
        }
        LightingPowerup.prototype.activate = function () {
            var _this = this;
            _super.prototype.activate.call(this);
            var delay = 0;
            var balls = Phaser.ArrayUtils.shuffle(this.getSuitableBalls());
            var currentPortion = [this.targetBall];
            while (currentPortion) {
                for (var _i = 0, currentPortion_1 = currentPortion; _i < currentPortion_1.length; _i++) {
                    var ball = currentPortion_1[_i];
                    var nextPortion = this.getBallsPortion(balls);
                    if (nextPortion) {
                        for (var _a = 0, nextPortion_1 = nextPortion; _a < nextPortion_1.length; _a++) {
                            var nextPortionBall = nextPortion_1[_a];
                            this.add(new src.Lighting(ball, nextPortionBall).setDelay(delay));
                        }
                        delay += src.Lighting.TOTAL_FRAMES / src.Lighting.FPS * 1000 + src.Settings.game.LIGHTING_DELAY_BETWEEN_STRIKES;
                    }
                    currentPortion = nextPortion;
                }
            }
            this.game.time.events.add(delay, function () { return _this.explodeInvisibleBalls(); });
        };
        LightingPowerup.prototype.refresh = function (ball) {
            _super.prototype.refresh.call(this, ball);
            this.activate();
        };
        LightingPowerup.prototype.update = function () {
            _super.prototype.update.call(this);
            this.duration = this.children.length > 0 ? 10000 : this.duration > src.Settings.LIGHTING_STRIKE_COLLAPSE_DELAY ? src.Settings.LIGHTING_STRIKE_COLLAPSE_DELAY : this.duration;
            if (this.children.length == 0 && this.duration == src.Settings.LIGHTING_STRIKE_COLLAPSE_DELAY) {
                for (var _i = 0, _a = this.powerupManager.level.pathManager.paths; _i < _a.length; _i++) {
                    var path = _a[_i];
                    path.speedManager.hasLightingPowerupActivated = true;
                }
            }
        };
        LightingPowerup.prototype.getSuitableBalls = function () {
            var balls = [];
            for (var _i = 0, _a = this.powerupManager.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball && ball.isAlive && ball.visible && ball != this.targetBall && ball.color == this.targetBall.color) {
                        balls.push(ball);
                    }
                }
            }
            return balls;
        };
        LightingPowerup.prototype.getBallsPortion = function (balls) {
            if (balls.length == 0) {
                return null;
            }
            if (balls.length < src.Settings.game.LIGHTING_MIN_TARGETS) {
                return balls.splice(0, balls.length);
            }
            var ballsCount = src.Settings.game.LIGHTING_MIN_TARGETS + Math.floor(Math.random() * (src.Settings.game.LIGHTING_MAX_TARGETS + 1 - src.Settings.game.LIGHTING_MIN_TARGETS));
            return balls.splice(0, ballsCount > balls.length ? balls.length : ballsCount);
        };
        LightingPowerup.prototype.explodeInvisibleBalls = function () {
            for (var _i = 0, _a = this.powerupManager.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                for (var _b = 0, _c = path.ballManager.balls; _b < _c.length; _b++) {
                    var ball = _c[_b];
                    if (ball && ball.isAlive && !ball.visible && ball != this.targetBall && ball.color == this.targetBall.color) {
                        src.ScoreManager.instance.displayScores(src.ScoreManager.instance.calculateScores(1), false, ball.color, ball.x, ball.y, Phaser.Math.random(5, 150), true, true);
                        ball.explodeBall();
                    }
                }
            }
        };
        return LightingPowerup;
    }(src.Powerup));
    src.LightingPowerup = LightingPowerup;
})(src || (src = {}));
var src;
(function (src) {
    var RewindPowerup = (function (_super) {
        __extends(RewindPowerup, _super);
        function RewindPowerup(powerupManager, targetBall) {
            return _super.call(this, powerupManager, src.PowerupType.REWIND, false, src.Settings.game.REWIND_POWERUP_DURATION, targetBall) || this;
        }
        RewindPowerup.prototype.activate = function () {
            _super.prototype.activate.call(this);
            for (var _i = 0, _a = this.powerupManager.level.pathManager.paths; _i < _a.length; _i++) {
                var path = _a[_i];
                this.game.sound.play('rewind', 0.7);
                path.speedManager.activateRewind();
            }
        };
        return RewindPowerup;
    }(src.Powerup));
    src.RewindPowerup = RewindPowerup;
})(src || (src = {}));
var src;
(function (src) {
    var SlowdownPowerup = (function (_super) {
        __extends(SlowdownPowerup, _super);
        function SlowdownPowerup(powerupManager, targetBall) {
            var _this = _super.call(this, powerupManager, src.PowerupType.SLOWDOWN, true, src.Settings.game.SLOWDOWN_POWERUP_DURATION, targetBall) || this;
            _this.isFrozen = false;
            _this.isMelted = false;
            _this.countdown = 0;
            _this.slowdownMultiplier = 1;
            _this.countdown = _this.startingDuration;
            return _this;
        }
        SlowdownPowerup.prototype.activate = function () {
            _super.prototype.activate.call(this);
            this.isActive = false;
            this.slowdownMultiplier = 1;
            this.freezeEffect = this.add(new src.FreezeEffect(this));
            this.freezeEffect.freeze();
        };
        SlowdownPowerup.prototype.refresh = function (ball) {
            _super.prototype.refresh.call(this, ball);
            this.countdown = this.startingDuration;
            this.isActive = false;
            this.isFrozen = false;
            this.isMelted = false;
            this.slowdownMultiplier = 1;
            this.freezeEffect.freeze();
        };
        SlowdownPowerup.prototype.onFrozen = function () {
            this.isFrozen = true;
        };
        SlowdownPowerup.prototype.onMelted = function () {
            this.isMelted = true;
            this.duration = 0;
        };
        SlowdownPowerup.prototype.update = function () {
            _super.prototype.update.call(this);
            if (this.isDead) {
                return;
            }
            this.duration = this.startingDuration;
            if (this.isMelted) {
                this.killPowerup();
                return;
            }
            if (this.isFrozen && !this.isMelted) {
                this.countdown -= this.game.time.elapsedMS;
                if (this.countdown <= 0) {
                    this.isActive = true;
                    this.freezeEffect.melt();
                    this.countdown = Number.MAX_VALUE;
                }
            }
        };
        return SlowdownPowerup;
    }(src.Powerup));
    src.SlowdownPowerup = SlowdownPowerup;
})(src || (src = {}));
var src;
(function (src) {
    var Tunnel = (function (_super) {
        __extends(Tunnel, _super);
        function Tunnel(tunnelManager, path, startIndex, startRotation, endIndex, endRotation) {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.tunnelManager = tunnelManager;
            _this.path = path;
            _this.startPoint = path.pathPoints[startIndex];
            _this.endPoint = path.pathPoints[endIndex];
            _this.startPosition = startIndex;
            _this.endPosition = endIndex;
            _this.entrancePosition = _this.path.calculateRelativePosition(startIndex, -60);
            _this.entrancePosition = _this.entrancePosition < 0 ? startIndex : _this.entrancePosition;
            _this.exitPosition = _this.path.calculateRelativePosition(endIndex, 45);
            _this.exitPosition = _this.exitPosition < 0 ? endIndex : _this.exitPosition;
            _this.entranceBottom = _this.tunnelManager.level.backgroundManager.add(new src.TunnelBottom(_this.startPoint.x, _this.startPoint.y, startRotation));
            _this.entranceTop = _this.add(new src.TunnelTop(_this.startPoint.x, _this.startPoint.y, startRotation));
            _this.exitBottom = _this.tunnelManager.level.backgroundManager.add(new src.TunnelBottom(_this.endPoint.x, _this.endPoint.y, endRotation));
            _this.exitTop = _this.add(new src.TunnelTop(_this.endPoint.x, _this.endPoint.y, endRotation));
            return _this;
        }
        /**
         * DESTROY
         */
        Tunnel.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.tunnelManager = null;
            this.path = null;
            this.startPoint = null;
            this.endPoint = null;
            this.entranceTop = null;
            this.entranceBottom = null;
            this.exitTop = null;
            this.exitBottom = null;
        };
        return Tunnel;
    }(Phaser.Group));
    src.Tunnel = Tunnel;
})(src || (src = {}));
var src;
(function (src) {
    var TunnelBottom = (function (_super) {
        __extends(TunnelBottom, _super);
        function TunnelBottom(x, y, rotation) {
            var _this = _super.call(this, src.App.instance, x, y, src.Settings.GAME_ATLAS, 'tunnelBot' + '0000') || this;
            _this.anchor.set(0.5, -0.3);
            _this.rotation = rotation;
            return _this;
        }
        return TunnelBottom;
    }(Phaser.Sprite));
    src.TunnelBottom = TunnelBottom;
})(src || (src = {}));
var src;
(function (src) {
    var TunnelTop = (function (_super) {
        __extends(TunnelTop, _super);
        function TunnelTop(x, y, rotation) {
            var _this = _super.call(this, src.App.instance, x, y, src.Settings.GAME_ATLAS, 'tunnelTop' + '0000') || this;
            _this.anchor.set(0.5, 0.35);
            _this.rotation = rotation;
            return _this;
        }
        return TunnelTop;
    }(Phaser.Sprite));
    src.TunnelTop = TunnelTop;
})(src || (src = {}));
var src;
(function (src) {
    var SoundController = (function () {
        function SoundController() {
            this.soundInstances = {};
            this.swapSoundIndex = 1;
            this.defaultMusicVolume = 0.3;
            this.chokedMusicVolume = 0.1;
            this.defaultMusicVolume = src.App.instance.device.desktop ? 0.3 : 0.25;
            this.menuTheme = src.App.instance.add.sound('themeA', this.defaultMusicVolume, true);
            this.gameplayThemeA = src.App.instance.add.sound('themeB', this.defaultMusicVolume, false);
            this.gameplayThemeB = src.App.instance.add.sound('themeC', this.defaultMusicVolume, false);
        }
        Object.defineProperty(SoundController, "instance", {
            get: function () {
                return SoundController._instance ? SoundController._instance :
                    SoundController._instance = new SoundController();
            },
            enumerable: true,
            configurable: true
        });
        SoundController.prototype.isDecodingSupported = function () {
            return src.App.instance.sound.usingWebAudio;
        };
        /**
         * MUSIC
         */
        SoundController.prototype.switchToMenuMusic = function () {
            if (this.mode != MusicMode.MENU_MUSIC) {
                this.mode = MusicMode.MENU_MUSIC;
                this.removeListeners();
                this.stopMusic();
                this.currentTheme = this.menuTheme.play('', 0, 0);
                this.currentTheme.fadeTo(1500, this.defaultMusicVolume);
            }
        };
        SoundController.prototype.switchToInGameMusic = function () {
            if (this.mode != MusicMode.GAMEPLAY_MUSIC) {
                this.stopMusic();
                this.mode = MusicMode.GAMEPLAY_MUSIC;
                this.addListeners();
                this.currentTheme = Math.random() > 0.5 ? this.gameplayThemeA.play('', 0, 0) : this.gameplayThemeB.play('', 0, 0);
                this.currentTheme.fadeTo(1200, this.defaultMusicVolume);
            }
        };
        SoundController.prototype.stopMusic = function () {
            if (this.menuTheme.isPlaying) {
                this.menuTheme.stop();
            }
            if (this.gameplayThemeA.isPlaying) {
                this.gameplayThemeA.stop();
            }
            if (this.gameplayThemeB.isPlaying) {
                this.gameplayThemeB.stop();
            }
        };
        SoundController.prototype.switchGameplayTheme = function () {
            if (this.mode == MusicMode.GAMEPLAY_MUSIC) {
                if (this.currentTheme == this.gameplayThemeA) {
                    this.currentTheme = this.gameplayThemeB.play();
                }
                else if (this.currentTheme == this.gameplayThemeB) {
                    this.currentTheme = this.gameplayThemeA.play();
                }
            }
        };
        SoundController.prototype.addListeners = function () {
            var _this = this;
            this.gameplayThemeA.onStop.add(function () {
                _this.switchGameplayTheme();
            });
            this.gameplayThemeB.onStop.add(function () {
                _this.switchGameplayTheme();
            });
        };
        SoundController.prototype.removeListeners = function () {
            this.gameplayThemeA.onStop.removeAll();
            this.gameplayThemeB.onStop.removeAll();
        };
        /**
         * SOUNDS
         */
        SoundController.prototype.playSwapSound = function () {
            src.App.instance.sound.play('ball_swap0' + (this.swapSoundIndex++ % 2 + 1), 0.7);
        };
        /**
         * MUSIC
         */
        SoundController.prototype.chokeMusicVolume = function (duration) {
            if (duration === void 0) { duration = 500; }
            if (this.currentTheme) {
                this.currentTheme.fadeTo(duration, this.chokedMusicVolume);
            }
        };
        SoundController.prototype.restoreMusicVolume = function (duration) {
            if (duration === void 0) { duration = 500; }
            if (this.currentTheme) {
                this.currentTheme.fadeTo(duration, this.defaultMusicVolume);
            }
        };
        SoundController._instance = null;
        return SoundController;
    }());
    src.SoundController = SoundController;
    var MusicMode;
    (function (MusicMode) {
        MusicMode[MusicMode["MENU_MUSIC"] = 0] = "MENU_MUSIC";
        MusicMode[MusicMode["GAMEPLAY_MUSIC"] = 1] = "GAMEPLAY_MUSIC";
    })(MusicMode = src.MusicMode || (src.MusicMode = {}));
})(src || (src = {}));
var src;
(function (src) {
    var AutoResizeableState = (function (_super) {
        __extends(AutoResizeableState, _super);
        function AutoResizeableState() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        AutoResizeableState.prototype.init = function (containerWidth, containerHeight) {
            if (containerWidth === void 0) { containerWidth = src.CustomScaleManager.ORIGINAL_WIDTH; }
            if (containerHeight === void 0) { containerHeight = src.CustomScaleManager.ORIGINAL_HEIGHT; }
            _super.prototype.init.call(this);
            this.containerWidth = containerWidth;
            this.containerHeight = containerHeight;
            this.container = this.add.existing(this.game.make.group(null));
            this.resize();
        };
        AutoResizeableState.prototype.addChild = function (child) {
            return this.container.add(child);
        };
        AutoResizeableState.prototype.getInputPosition = function () {
            return new Phaser.Point((this.game.input.activePointer.x - this.container.x) / src.CustomScaleManager.SCALE_X, (this.game.input.activePointer.y - this.container.y) / src.CustomScaleManager.SCALE_Y);
        };
        AutoResizeableState.prototype.resize = function (width, height) {
            if (width === void 0) { width = 0; }
            if (height === void 0) { height = 0; }
            this.container.scale.set(src.CustomScaleManager.SCALE_X, src.CustomScaleManager.SCALE_Y);
            this.container.position.set(src.CustomScaleManager.WIDTH / 2 - this.containerWidth * src.CustomScaleManager.SCALE_X / 2, src.CustomScaleManager.HEIGHT / 2 - this.containerHeight * src.CustomScaleManager.SCALE_Y / 2);
        };
        AutoResizeableState.prototype.shutdown = function () {
            this.container.destroy();
            this.container = null;
        };
        return AutoResizeableState;
    }(Phaser.State));
    src.AutoResizeableState = AutoResizeableState;
})(src || (src = {}));
var src;
(function (src) {
    var Boot = (function (_super) {
        __extends(Boot, _super);
        function Boot() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        Boot.prototype.init = function () {
            this.game.scale.scaleMode = Phaser.ScaleManager.RESIZE;
            this.game.scale.fullScreenScaleMode = Phaser.ScaleManager.RESIZE;
            this.game.scale.pageAlignHorizontally = true;
            this.game.scale.pageAlignVertically = true;
            if (this.game.device.android) {
                this.game.input.mouse.enabled = !this.game.device.mspointer;
            }
            this.game.scale.setResizeCallback(this.resizeCallback, this);
            this.game.scale.onSizeChange.add(this.sizeChanged, this);
        };
        Boot.prototype.preload = function () {
            this.game.load.atlas(src.Settings.PRELOADER_ATLAS, 'img/' + src.Settings.PRELOADER_ATLAS + '.png', 'img/' + src.Settings.PRELOADER_ATLAS + '.json');
        };
        Boot.prototype.create = function () {
            this.input.maxPointers = 1;
            this.stage.disableVisibilityChange = true;
            if (this.game.device.desktop) {
                this.game.canvas.oncontextmenu = function (e) {
                    e.preventDefault();
                };
            }
            this.game.state.start('Preloader', true, false);
        };
        Boot.prototype.resizeCallback = function (manager, bounds) {
        };
        Boot.prototype.sizeChanged = function (scaleManager, w, h) {
            src.CustomScaleManager.update(w, h);
        };
        return Boot;
    }(Phaser.State));
    src.Boot = Boot;
})(src || (src = {}));
///<reference path="AutoResizeableState.ts"/>
var src;
(function (src) {
    var Level = (function (_super) {
        __extends(Level, _super);
        function Level() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        Level.prototype.create = function () {
            var _this = this;
            this.maskGraphics = this.addChild(this.game.make.graphics(0, 0));
            this.maskGraphics.beginFill(0x000000, 1).drawRect(0, 0, src.CustomScaleManager.ORIGINAL_WIDTH, src.CustomScaleManager.ORIGINAL_HEIGHT).endFill();
            this.maskedContainer = this.addChild(this.game.make.group(null));
            this.gameStateManager = this.maskedContainer.add(new src.GameStateManager(this));
            this.backgroundManager = this.maskedContainer.add(new src.BackgroundManager(this));
            this.touchInputManager = this.maskedContainer.add(new src.TouchInputManager(this));
            this.wayManager = this.maskedContainer.add(new src.WayManager(this));
            this.pathManager = this.maskedContainer.add(new src.PathManager(this));
            this.daemonManager = this.maskedContainer.add(new src.DaemonManager(this));
            this.coinManager = this.maskedContainer.add(new src.CoinManager(this));
            this.cannonManager = this.maskedContainer.add(new src.CannonManager(this));
            this.powerupManager = this.maskedContainer.add(new src.PowerupManager(this));
            this.foregroundManager = this.addChild(new src.ForegroundManager(this));
            this.uiManager = this.addChild(new src.UIManager(this));
            this.effectsManager = this.addChild(new src.EffectsManager(this));
            this.maskedContainer.mask = this.maskGraphics;
            if (src.Settings.MUSIC_ENABLED_BY_DEFAULT) {
                src.SoundController.instance.restoreMusicVolume();
                src.SoundController.instance.switchToInGameMusic();
            }
            src.StatsManager.instance.clear();
            src.ScoreManager.instance.clear();
            this.pathManager.buildPaths();
            this.daemonManager.buildDaaemons();
            this.wayManager.buildTexture();
            this.coinManager.buildCoins();
            this.cannonManager.buildAll();
            src.TutorialManager.instance.dispatchLevelStart(function () { return _this.gameStateManager.startInitialization(); });
            src.WindowManager.instance.endTransition();
            window.famobi_analytics.trackScreen(window.famobi_analytics.SCREEN_LEVEL);
            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_LEVELSTART, {
                levelName: '' + src.Settings.CURRENT_LEVEL
            });
        };
        Level.prototype.update = function () {
            if (this.gameStateManager.isStarted && !this.gameStateManager.isPaused) {
                src.StatsManager.instance.update();
                src.ScoreManager.instance.update();
            }
        };
        Level.prototype.shutdown = function () {
            this.gameStateManager.destroy();
            this.gameStateManager = null;
            this.backgroundManager.destroy();
            this.backgroundManager = null;
            this.touchInputManager.destroy();
            this.touchInputManager = null;
            this.pathManager.destroy();
            this.pathManager = null;
            this.daemonManager.destroy();
            this.daemonManager = null;
            this.wayManager.destroy();
            this.wayManager = null;
            this.coinManager.destroy();
            this.coinManager = null;
            this.cannonManager.destroy();
            this.cannonManager = null;
            this.effectsManager.destroy();
            this.effectsManager = null;
            this.powerupManager.destroy();
            this.powerupManager = null;
            this.foregroundManager.destroy();
            this.foregroundManager = null;
            this.uiManager.destroy();
            this.uiManager = null;
        };
        return Level;
    }(src.AutoResizeableState));
    src.Level = Level;
})(src || (src = {}));
///<reference path="AutoResizeableState.ts"/>
var src;
(function (src) {
    var LevelsMap = (function (_super) {
        __extends(LevelsMap, _super);
        function LevelsMap() {
            var _this = _super !== null && _super.apply(this, arguments) || this;
            _this.digitContainerRadius = 444;
            _this.angleBetweenDigits = Math.PI / 6;
            _this._currentLevelIndex = 0;
            _this.angularSpeed = 0;
            _this.currentStep = 1;
            _this.isSpinning = false;
            _this.isPlayButtonEnabled = true;
            _this.isWheelPressed = false;
            _this.dragDeltaAngle = 0;
            return _this;
        }
        /**
         *  INHERITED METHODS
         */
        LevelsMap.prototype.create = function () {
            this.wheelSoundLastTimestamp = this.game.time.now;
            this.buildContent();
            this.updateSoundButtons();
            src.TutorialManager.instance.dispatchLevelsMapOpening();
            src.WindowManager.instance.endTransition();
            window.famobi_analytics.trackScreen(window.famobi_analytics.SCREEN_LEVELSELECT);
        };
        /**
         * PRIVATE METHODS
         */
        LevelsMap.prototype.buildContent = function () {
            this.maskGraphics = this.addChild(this.game.make.graphics(0, -src.CustomScaleManager.ORIGINAL_WIDTH / 2));
            this.maskGraphics.beginFill(0x000000, 1).drawRect(0, 0, src.CustomScaleManager.ORIGINAL_WIDTH, 3 * src.CustomScaleManager.ORIGINAL_WIDTH).endFill();
            this.container.mask = this.maskGraphics;
            this.backgroundImage = this.addChild(this.game.make.image(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2, 'mainMenu'));
            this.backgroundImage.anchor.set(0.5);
            this.responsiveContainer = this.addChild(this.game.make.group(null));
            this.circleBackgroundLeft = this.responsiveContainer.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2 - 224, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 - 142, src.Settings.UI_ATLAS, 'digitContainerBackground' + '0000'));
            this.circleBackgroundLeft.anchor.set(0.5, 0.5);
            this.circleBackgroundCenter = this.responsiveContainer.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2 - 3, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 - 207, src.Settings.UI_ATLAS, 'digitContainerBackground' + '0000'));
            this.circleBackgroundCenter.anchor.set(0.5, 0.5);
            this.circleBackgroundRight = this.responsiveContainer.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2 + 220, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 - 142, src.Settings.UI_ATLAS, 'digitContainerBackground' + '0000'));
            this.circleBackgroundRight.anchor.set(0.5, 0.5);
            this.digitContainer = this.responsiveContainer.add(this.game.make.group(null));
            this.digitContainer.position.set(src.CustomScaleManager.ORIGINAL_WIDTH / 2 - 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 236);
            this.levelsImage = this.responsiveContainer.add(this.game.make.image(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT, 'levels'));
            this.levelsImage.anchor.set(0.5, 1);
            this.arrow = this.responsiveContainer.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 - 380, src.Settings.UI_ATLAS, 'levelsArrow' + '0000'));
            this.arrow.anchor.set(0.5, 0);
            this.wheel = this.responsiveContainer.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2 - 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 184, src.Settings.UI_ATLAS, 'levelsWheel' + '0000'));
            this.wheel.anchor.set(0.5, 0.5);
            this.buttonHome = this.addChild(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonHomeLevels', src.CustomScaleManager.ORIGINAL_WIDTH / 2 + 240, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 - 400, this.menuClicked, this));
            this.buttonHome.anchor.set(0.5);
            // this.buttonSoundOn = this.addChild(ButtonUtils.createButton(Settings.UI_ATLAS, 'buttonSoundOnMainMenu', CustomScaleManager.ORIGINAL_WIDTH / 2 + 240, CustomScaleManager.ORIGINAL_HEIGHT / 2 - 400, this.soundOnClicked, this));
            // this.buttonSoundOn.anchor.set(0.5);
            //
            // this.buttonSoundOff = this.addChild(ButtonUtils.createButton(Settings.UI_ATLAS, 'buttonSoundOffMainMenu', CustomScaleManager.ORIGINAL_WIDTH / 2 + 240, CustomScaleManager.ORIGINAL_HEIGHT / 2 - 400, this.soundOffClicked, this));
            // this.buttonSoundOff.anchor.set(0.5);
            this.playButton = this.responsiveContainer.add(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 185, src.Settings.UI_ATLAS, 'levelsPlayButton0000'));
            this.playButton.inputEnabled = true;
            this.playButton.input.useHandCursor = true;
            this.playButton.input.pixelPerfectClick = true;
            this.playButton.events.onInputDown.add(this.onPlayButtonDown, this);
            this.playButton.events.onInputUp.add(this.onPlayButtonUp, this);
            this.playButton.anchor.set(0.5);
            this.buildLevelNumbers();
            this.resize(0, 0);
        };
        LevelsMap.prototype.buildLevelNumbers = function () {
            for (var i = 1; i <= src.Settings.TOTAL_LEVELS; i++) {
                this.digitContainer.add(new src.LevelIndicator(i, i > src.Settings.LAST_UNLOCKED_LEVEL && !src.Settings.UNLOCK_ALL_LEVELS));
            }
            this.currentLevelIndex = src.Settings.CURRENT_LEVEL < 1 ? 1 : src.Settings.LAST_UNLOCKED_LEVEL > src.Settings.TOTAL_LEVELS ? src.Settings.TOTAL_LEVELS : src.Settings.LAST_UNLOCKED_LEVEL;
            this.wheel.rotation = (src.Settings.LAST_UNLOCKED_LEVEL - 1) * 2 * Math.PI / src.Settings.LEVELS_WHEEL_AMPLIFIER;
            this.updateWheel(0);
            if (!LevelsMap.firstTimeSpinned) {
                this.playButton.alpha = 0;
                LevelsMap.firstTimeSpinned = true;
                this.angularSpeed = 0;
                this.currentStep = 18;
                this.isSpinning = true;
            }
            else {
                this.addListeners();
            }
        };
        /**
         * UPDATE HANDLER
         */
        LevelsMap.prototype.update = function () {
            _super.prototype.update.call(this, this.game);
            if (this.isSpinning) {
                this.angularSpeed = 3.15 * (1 / Math.sqrt(this.currentStep) - 0.0577);
                this.currentStep += 1;
                if (this.angularSpeed < 0.0) {
                    this.isSpinning = false;
                    this.addListeners();
                    this.finalizeWheelRotation();
                }
                else {
                    this.updateWheel(this.angularSpeed, 1);
                }
            }
            else if (this.isWheelPressed) {
                this.updateWheel(this.getDeltaAngle(this.wheel.rotation, Phaser.Math.angleBetween(this.wheel.x, this.wheel.y, this.getInputPosition().x - this.responsiveContainer.x, this.getInputPosition().y - this.responsiveContainer.y) + Math.PI / 2 - this.dragDeltaAngle));
                if (this.isPlayButtonEnabled && Phaser.Math.distance(this.playButton.x, this.playButton.y, this.getInputPosition().x - this.responsiveContainer.x, this.getInputPosition().y - this.responsiveContainer.y) > this.playButton.width / 2) {
                    this.hidePlayButton();
                }
            }
        };
        LevelsMap.prototype.resize = function (width, height) {
            _super.prototype.resize.call(this, width, height);
            if (this.responsiveContainer) {
                this.buttonHome.y = 80 - (Math.min(src.CustomScaleManager.HEIGHT / src.CustomScaleManager.SCALE_Y, 2 * src.CustomScaleManager.ORIGINAL_WIDTH) - src.CustomScaleManager.ORIGINAL_HEIGHT) / 2;
                this.responsiveContainer.y = (Math.min(src.CustomScaleManager.HEIGHT / src.CustomScaleManager.SCALE_Y, 2 * src.CustomScaleManager.ORIGINAL_WIDTH) - src.CustomScaleManager.ORIGINAL_HEIGHT) / 2;
            }
        };
        /**
         * PRIVATE METHODS
         */
        LevelsMap.prototype.easeIn = function (k, easingPower) {
            return Math.pow(k, easingPower);
        };
        LevelsMap.prototype.getNormalizedLevelIndex = function (index) {
            return (index >= 0 ? index % src.Settings.TOTAL_LEVELS : src.Settings.TOTAL_LEVELS + index % src.Settings.TOTAL_LEVELS) % src.Settings.TOTAL_LEVELS;
        };
        LevelsMap.prototype.getDeltaAngle = function (angleA, angleB) {
            var currentAngle = Phaser.Math.normalizeAngle(angleA);
            var targetAngle = Phaser.Math.normalizeAngle(angleB);
            if (Math.abs(targetAngle - currentAngle) > Math.PI) {
                if (currentAngle < targetAngle) {
                    currentAngle += 2 * Math.PI;
                }
                else {
                    targetAngle += 2 * Math.PI;
                }
            }
            return targetAngle - currentAngle;
        };
        LevelsMap.prototype.updateVisibleNumbers = function () {
            //set all numbers to invisible state
            this.digitContainer.children.forEach(function (digit) { return digit.visible = false; });
            this.showAt(this.getDigit(this.currentLevelIndex, -1), -1);
            this.showAt(this.getDigit(this.currentLevelIndex, 0), 0);
            this.showAt(this.getDigit(this.currentLevelIndex, 1), 1);
        };
        LevelsMap.prototype.getDigit = function (index, deltaIndex) {
            var digitIndex = ((index + deltaIndex) % src.Settings.TOTAL_LEVELS <= 0) ? src.Settings.TOTAL_LEVELS : (index + deltaIndex) % src.Settings.TOTAL_LEVELS;
            return this.digitContainer.getChildAt(digitIndex - 1);
        };
        LevelsMap.prototype.showAt = function (digit, position) {
            digit.visible = true;
            var targetPoint = new Phaser.Point(0, -this.digitContainerRadius);
            targetPoint.rotate(0, 0, position * this.angleBetweenDigits, false);
            digit.position.copyFrom(targetPoint);
            digit.rotation = position * this.angleBetweenDigits;
        };
        LevelsMap.prototype.updateWheel = function (angleDifference, easingPower) {
            if (easingPower === void 0) { easingPower = src.Settings.LEVELS_WHEEL_EASING_POWER; }
            this.wheel.rotation += angleDifference;
            var digitContainerAngle = (-this.wheel.rotation * this.angleBetweenDigits / (2 * Math.PI) * src.Settings.LEVELS_WHEEL_AMPLIFIER);
            this.currentLevelIndex = this.getNormalizedLevelIndex(-Math.floor(digitContainerAngle / this.angleBetweenDigits + 0.5)) + 1;
            var actualIndex = digitContainerAngle / this.angleBetweenDigits;
            while (actualIndex < -src.Settings.TOTAL_LEVELS + 0.5) {
                actualIndex += src.Settings.TOTAL_LEVELS;
            }
            while (actualIndex > 0.5) {
                actualIndex -= src.Settings.TOTAL_LEVELS;
            }
            var difference = Math.abs(actualIndex) + 1 - this.currentLevelIndex;
            if (actualIndex > 0) {
                difference = -difference % 0.5;
            }
            //update visibility
            this.updateVisibleNumbers();
            //set angle
            this.digitContainer.rotation = (difference > 0 ? -this.angleBetweenDigits / 2 * this.easeIn(2 * Math.abs(difference), easingPower) : this.angleBetweenDigits / 2 * this.easeIn(2 * Math.abs(difference), easingPower));
        };
        LevelsMap.prototype.finalizeWheelRotation = function () {
            var _this = this;
            var deltaAngle = this.wheel.rotation % (2 * Math.PI / src.Settings.LEVELS_WHEEL_AMPLIFIER);
            if (deltaAngle == 0) {
                this.showPlayButton();
                return;
            }
            else if (Math.abs(deltaAngle) > Math.PI / src.Settings.LEVELS_WHEEL_AMPLIFIER) {
                deltaAngle = Phaser.Math.sign(deltaAngle) * 2 * Math.PI / src.Settings.LEVELS_WHEEL_AMPLIFIER - deltaAngle;
            }
            else {
                deltaAngle = -deltaAngle;
            }
            this.game.add.tween(this.wheel)
                .to({ rotation: this.wheel.rotation + deltaAngle }, 400 * Math.abs(deltaAngle) / (Math.PI / src.Settings.LEVELS_WHEEL_AMPLIFIER), Phaser.Easing.Quadratic.Out, true)
                .onUpdateCallback(function () { return _this.updateWheel(0); })
                .onComplete.add(function () {
                _this.updateWheel(0);
                _this.showPlayButton();
            });
        };
        LevelsMap.prototype.showPlayButton = function () {
            if (this.currentLevelIndex <= src.Settings.LAST_UNLOCKED_LEVEL || src.Settings.UNLOCK_ALL_LEVELS) {
                this.isPlayButtonEnabled = true;
                this.game.tweens.removeFrom(this.playButton);
                this.game.tweens.removeFrom(this.playButton.scale);
                this.playButton.visible = true;
                this.game.add.tween(this.playButton)
                    .to({ alpha: 1 }, 170, Phaser.Easing.Cubic.Out, true);
                this.game.add.tween(this.playButton.scale)
                    .to({ x: 1, y: 1 }, 170, Phaser.Easing.Cubic.Out, true);
            }
        };
        LevelsMap.prototype.hidePlayButton = function () {
            var _this = this;
            this.isPlayButtonEnabled = false;
            this.game.tweens.removeFrom(this.playButton);
            this.game.tweens.removeFrom(this.playButton.scale);
            this.game.add.tween(this.playButton)
                .to({ alpha: 0 }, 150, Phaser.Easing.Cubic.In, true)
                .onComplete.add(function () {
                _this.playButton.visible = false;
            });
            this.game.add.tween(this.playButton.scale)
                .to({ x: 0.8, y: 0.8 }, 150, Phaser.Easing.Cubic.In, true);
        };
        LevelsMap.prototype.animateArrow = function (currentLevel, nextLevel) {
            var _this = this;
            var direction = (Math.abs(currentLevel - nextLevel) >= (src.Settings.TOTAL_LEVELS - 1)) ? (currentLevel < nextLevel ? -1 : 1) : (currentLevel < nextLevel ? 1 : -1);
            this.game.add.tween(this.arrow)
                .to({ rotation: direction * src.Settings.LEVELS_ARROW_ANGLE }, 75, Phaser.Easing.Linear.None, true, 0)
                .onComplete.add(function () { return _this.game.add.tween(_this.arrow)
                .to({ rotation: 0 }, 75, Phaser.Easing.Linear.None, true, 0); });
        };
        /**
         * INPUT HANDLERS
         */
        LevelsMap.prototype.addListeners = function () {
            this.wheel.inputEnabled = true;
            this.wheel.events.onInputDown.add(this.handleWheelInputDown, this);
            this.game.input.onUp.add(this.handleInputUp, this);
        };
        LevelsMap.prototype.onPlayButtonDown = function () {
            this.playButton.frameName = 'levelsPlayButton0001';
            this.handleWheelInputDown();
        };
        LevelsMap.prototype.onPlayButtonUp = function () {
            this.playButton.frameName = 'levelsPlayButton0000';
            if (this.isPlayButtonEnabled && this.playButton.alpha == 1 && Phaser.Math.distance(this.playButton.x, this.playButton.y, this.getInputPosition().x - this.responsiveContainer.x, this.getInputPosition().y - this.responsiveContainer.y) < this.playButton.width / 2) {
                this.onStartLevelPressed();
            }
            else {
                this.handleInputUp();
            }
        };
        LevelsMap.prototype.handleWheelInputDown = function () {
            this.game.tweens.removeFrom(this.wheel);
            this.isWheelPressed = true;
            this.dragDeltaAngle = this.getDeltaAngle(this.wheel.rotation, Phaser.Math.angleBetween(this.wheel.x, this.wheel.y, this.getInputPosition().x - this.responsiveContainer.x, this.getInputPosition().y - this.responsiveContainer.y) + Math.PI / 2);
        };
        LevelsMap.prototype.handleInputUp = function () {
            if (this.isWheelPressed) {
                this.isWheelPressed = false;
                this.finalizeWheelRotation();
                this.showPlayButton();
            }
        };
        LevelsMap.prototype.onStartLevelPressed = function () {
            if (this.currentLevelIndex <= src.Settings.LAST_UNLOCKED_LEVEL || src.Settings.UNLOCK_ALL_LEVELS) {
                this.game.sound.play('click', 0.9);
                src.Settings.CURRENT_LEVEL = this.currentLevelIndex > src.Settings.TOTAL_LEVELS ? src.Settings.TOTAL_LEVELS : this.currentLevelIndex < 1 ? 1 : this.currentLevelIndex;
                src.LevelManager.instance.cachedLevel = src.LevelStorage.instance.getLevel(src.Settings.CURRENT_LEVEL);
                src.WindowManager.instance.transitionTo("Level");
            }
        };
        /**
         * BUTTON HANDLERS
         */
        LevelsMap.prototype.menuClicked = function () {
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.transitionTo("MainMenu");
        };
        LevelsMap.prototype.soundOnClicked = function () {
            this.game.sound.mute = true;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);
        };
        LevelsMap.prototype.soundOffClicked = function () {
            this.game.sound.mute = false;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);
        };
        /**
         * STATE HANDLERS
         */
        LevelsMap.prototype.updateSoundButtons = function () {
            // if (this.game.sound.mute) {
            //     this.buttonSoundOn.visible = false;
            //     this.buttonSoundOff.visible = true;
            // } else {
            //     this.buttonSoundOn.visible = true;
            //     this.buttonSoundOff.visible = false;
            // }
        };
        Object.defineProperty(LevelsMap.prototype, "currentLevelIndex", {
            /**
             * GETTERS & SETTERS
             */
            get: function () {
                return this._currentLevelIndex;
            },
            set: function (value) {
                if (value != 0 && value != this._currentLevelIndex && this.game.time.now - this.wheelSoundLastTimestamp > src.Settings.LEVELS_WHEEL_MIN_SOUND_INTERVAL) {
                    src.App.instance.sound.play('wheel', 0.7);
                    this.animateArrow(this._currentLevelIndex, value);
                    this.wheelSoundLastTimestamp = this.game.time.now;
                    if (this.isPlayButtonEnabled) {
                        this.hidePlayButton();
                    }
                    if (this.isWheelPressed) {
                        src.TutorialManager.instance.dispatchWheelRotate(this.wheel.x, this.wheel.y);
                    }
                }
                this._currentLevelIndex = value;
            },
            enumerable: true,
            configurable: true
        });
        LevelsMap.firstTimeSpinned = false;
        return LevelsMap;
    }(src.AutoResizeableState));
    src.LevelsMap = LevelsMap;
})(src || (src = {}));
///<reference path="AutoResizeableState.ts"/>
var src;
(function (src) {
    var MainMenu = (function (_super) {
        __extends(MainMenu, _super);
        function MainMenu() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        /**
         *  INHERITED METHODS
         */
        MainMenu.prototype.create = function () {
            this.game.time.advancedTiming = true;
            this.buildContent();

            //if(window.famobi.localStorage.getItem("muted")) {
            //    game.sound.mute = true;
            //}
            var dityTactic = this;
            window.famobi_onMuteRequested = function(){
                dityTactic.game.sound.mute = true;
                dityTactic.updateSoundButtons();

                window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                    bgmVolume: 0.0,
                    sfxVolume: 0.0
                });
                window.famobi.localStorage.setItem("muted", true);
            };

            window.famobi_onUnmuteRequested = function(){
                dityTactic.game.sound.mute = false;
                dityTactic.updateSoundButtons();

                window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                bgmVolume: 1.0,
                sfxVolume: 1.0
                });
                window.famobi.localStorage.removeItem("muted");
            }

            if(typeof window.famobi.audio == "undefined" || window.famobi.audio.isEnabled()){
                famobi_onUnmuteRequested();
            }
            else{
                famobi_onMuteRequested();
            }

            this.updateSoundButtons();
            if (src.Settings.MUSIC_ENABLED_BY_DEFAULT) {
                src.SoundController.instance.switchToMenuMusic();
            }
            src.WindowManager.instance.endTransition();
            window.famobi_analytics.trackScreen(window.famobi_analytics.SCREEN_HOME);
        };
        /**
         * PRIVATE METHODS
         */
        MainMenu.prototype.buildContent = function () {
            var _this = this;
            this.maskGraphics = this.addChild(this.game.make.graphics(0, -src.CustomScaleManager.ORIGINAL_WIDTH / 4));
            this.maskGraphics.beginFill(0x000000, 1).drawRect(0, 0, src.CustomScaleManager.ORIGINAL_WIDTH, 3 * src.CustomScaleManager.ORIGINAL_WIDTH).endFill();
            this.container.mask = this.maskGraphics;
            this.backgroundImage = this.addChild(this.game.make.image(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2, 'mainMenu'));
            this.backgroundImage.anchor.set(0.5);
            this.bottomGrass = this.addChild(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT, src.Settings.UI_ATLAS, 'menuGrassBottom' + '0000'));
            this.bottomGrass.anchor.set(0.5, 1);
            this.logo = this.addChild(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, -18, src.Settings.UI_ATLAS, 'gameLogo' + '0000'));
            this.logo.anchor.set(0.5);
            this.subLogo = this.addChild(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, 210, src.Settings.UI_ATLAS, 'gameSubLogo' + '0000'));
            this.subLogo.anchor.set(0.5);
            this.monster = this.addChild(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, -480, src.Settings.UI_ATLAS, 'monsterMainMenu' + '0000'));
            this.monster.anchor.set(0.5, 1);
            this.foregroundGrass = this.addChild(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 128, src.Settings.UI_ATLAS, 'grassMainMenu' + '0000'));
            this.foregroundGrass.anchor.set(0.5);
            this.buttonPlay = this.addChild(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonPlayMainMenu', src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 260, this.playClicked, this));
            this.buttonPlay.scale.set(0.9);
            this.buttonPlay.anchor.set(0.5);
            this.buttonCredits =
            (window.famobi.hasFeature("credits")) ? this.addChild(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonCreditsMainMenu', src.CustomScaleManager.ORIGINAL_WIDTH / 2 - 230, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 400, this.creditsClicked, this))
            : undefined;
            if(this.buttonCredits)this.buttonCredits.anchor.set(0.5);
            this.buttonMore = this.addChild(this.game.make.sprite(src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT - 9, 'more_games'));
            this.buttonMore.scale.set(0.4);
            this.buttonMore.anchor.set(0.5, 1);
            this.buttonMore.inputEnabled = true;
            this.buttonMore.input.useHandCursor = true;
            this.buttonMore.events.onInputDown.add(function () { return _this.moreClicked(); });
            this.buttonSoundOn = this.addChild(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonSoundOnMainMenu', src.CustomScaleManager.ORIGINAL_WIDTH / 2 + 230, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 400, this.soundOnClicked, this));
            this.buttonSoundOn.anchor.set(0.5);
            this.buttonSoundOff = this.addChild(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonSoundOffMainMenu', src.CustomScaleManager.ORIGINAL_WIDTH / 2 + 230, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 400, this.soundOffClicked, this));
            this.buttonSoundOff.anchor.set(0.5);
            this.resize(0, 0);
            this.animateContent();
        };
        MainMenu.prototype.resize = function (width, height) {
            _super.prototype.resize.call(this, width, height);
            if (this.bottomGrass) {
                this.bottomGrass.y = src.CustomScaleManager.ORIGINAL_HEIGHT + (Math.min(src.CustomScaleManager.HEIGHT / src.CustomScaleManager.SCALE_Y, 2 * src.CustomScaleManager.ORIGINAL_WIDTH) - src.CustomScaleManager.ORIGINAL_HEIGHT) / 2;
            }
        };
        MainMenu.prototype.animateContent = function () {
            var _this = this;
            this.monster.y = -480;
            this.monster.scale.set(1, 1);
            this.game.add.tween(this.monster)
                .to({ y: src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 140 }, 820, Phaser.Easing.Cubic.In, true, 100)
                .onComplete.add(function () {
                _this.game.sound.play('idol_hit_main_menu', 0.7);
                _this.game.camera.shake(0.008, 250);
            });
            this.game.add.tween(this.monster.scale)
                .to({ x: 1.11, y: 0.88 }, 120, Phaser.Easing.Linear.None, true, 800, 0, true)
                .onComplete.add(function () {
                var firstTween = _this.game.add.tween(_this.monster.scale)
                    .to({ x: 1.01, y: 0.99 }, 1500, Phaser.Easing.Sinusoidal.Out, true);
                var secondTween = _this.game.add.tween(_this.monster.scale)
                    .to({ x: 0.99, y: 1.01 }, 1500, Phaser.Easing.Sinusoidal.In);
                firstTween.chain(secondTween);
                secondTween.chain(firstTween);
            });
            this.logo.y = -340;
            this.game.add.tween(this.logo)
                .to({ y: 140 }, 800, Phaser.Easing.Back.Out, true, 850);
            this.subLogo.alpha = 0;
            this.subLogo.y = 235;
            this.subLogo.scale.set(0.5);
            this.game.add.tween(this.subLogo.scale)
                .to({ x: 1, y: 1 }, 300, Phaser.Easing.Sinusoidal.Out, true, 1450);
            this.game.add.tween(this.subLogo)
                .to({ alpha: 1, y: 215 }, 300, Phaser.Easing.Linear.None, true, 1450)
                .onComplete.add(function () {
                _this.game.add.tween(_this.subLogo.scale).to({
                    x: 1.02,
                    y: 1.02
                }, 1500, Phaser.Easing.Linear.None, true, 0, -1, true);
            });
        };
        /**
         * BUTTON HANDLERS
         */
        MainMenu.prototype.playClicked = function () {
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.transitionTo("LevelsMap");
        };
        MainMenu.prototype.moreClicked = function () {
            this.game.sound.play('click', 0.9);
            src.App.instance.navigateToSponsor();
        };
        MainMenu.prototype.creditsClicked = function () {
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.showCredits();
        };
        MainMenu.prototype.soundOnClicked = function () {
            this.game.sound.mute = true;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);

            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                bgmVolume: 0.0,
                sfxVolume: 0.0
            });
            window.famobi.localStorage.setItem("muted", true);
        };
        MainMenu.prototype.soundOffClicked = function () {
            this.game.sound.mute = false;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);

            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                bgmVolume: 1.0,
                sfxVolume: 1.0
            });
            window.famobi.localStorage.removeItem("muted");
        };
        /**
         * STATE HANDLERS
         */
        MainMenu.prototype.updateSoundButtons = function () {
            if(typeof window.famobi.audio == "undefined" || window.famobi.audio.hasControls()){
                if (this.game.sound.mute) {
                    this.buttonSoundOn.visible = false;
                    this.buttonSoundOff.visible = true;
                }
                else {
                    this.buttonSoundOn.visible = true;
                    this.buttonSoundOff.visible = false;
                }
            }
            else{
                this.buttonSoundOn.visible = false;
                this.buttonSoundOff.visible = false;
            }
        };
        return MainMenu;
    }(src.AutoResizeableState));
    src.MainMenu = MainMenu;
})(src || (src = {}));
///<reference path="AutoResizeableState.ts"/>
var src;
(function (src) {
    var Preloader = (function (_super) {
        __extends(Preloader, _super);
        function Preloader() {
            return _super !== null && _super.apply(this, arguments) || this;
        }
        Preloader.prototype.preload = function () {
            if (src.Settings.ENABLE_PRELOADER_OUTPUT) {
                this.enableDebugOutput();
            }
            this.preloaderIcon = this.addChild(this.game.make.sprite(this.containerWidth / 2 - 5, this.containerHeight / 2 - 140, src.Settings.PRELOADER_ATLAS, "preloaderIcon0000"));
            this.preloaderIcon.anchor.setTo(0.5, 0.5);
            this.game.add.tween(this.preloaderIcon.scale)
                .to({ x: 0.96, y: 0.96 }, 1000, Phaser.Easing.Linear.None, true, 0, -1, true);
            this.preloaderBack = this.addChild(this.game.make.sprite(this.containerWidth / 2 + 2, this.containerHeight / 2 + 2, src.Settings.PRELOADER_ATLAS, "preloaderBack0000"));
            this.preloaderBack.anchor.setTo(0.5, 0.5);
            this.preloaderBar = this.addChild(this.game.make.sprite(this.containerWidth / 2 - 181, this.containerHeight / 2, src.Settings.PRELOADER_ATLAS, "preloaderBar0000"));
            this.preloaderBar.anchor.setTo(0, 0.5);
            this.originalBarWidth = this.preloaderBar.width;
            this.preloaderFront = this.addChild(this.game.make.sprite(this.containerWidth / 2, this.containerHeight / 2, src.Settings.PRELOADER_ATLAS, "preloaderFront0000"));
            this.preloaderFront.anchor.setTo(0.5, 0.5);
            this.addChild(src.TextUtils.getShadowText(src.Settings.GAME_VERSION, 6, 6, 12, "#ffffff", "#462B1F", 1, 4));
            this.preloadText = src.TextUtils.getShadowText('0%', this.containerWidth / 2, this.containerHeight / 2, 32, "#ffffff", "#462B1F", 0, 5);
            this.addChild(this.preloadText);
            this.currentFileText = src.TextUtils.getStyledText("", this.containerWidth / 2, this.containerHeight - 20, 16, "#ffffff", "#462B1F", 4);
            this.addChild(this.currentFileText);
            this.game.load.onFileStart.add(this.onFileStart, this);
            this.game.load.onFileComplete.add(this.onFileComplete, this);
            this.game.load.onLoadComplete.add(this.onLoadingComplete, this);
            this.initSoundNames();
            for (var _i = 0, _a = this.soundNames; _i < _a.length; _i++) {
                var soundName = _a[_i];
                this.game.load.audio(soundName, ['sound/mp3/' + soundName + '.mp3', 'sound/m4a/' + soundName + '.m4a', 'sound/ogg/' + soundName + '.ogg']);
            }
            this.game.load.atlas(src.Settings.GAME_ATLAS, 'img/' + src.Settings.GAME_ATLAS + '.png', 'img/' + src.Settings.GAME_ATLAS + '.json');
            this.game.load.atlas(src.Settings.UI_ATLAS, 'img/' + src.Settings.UI_ATLAS + '.png', 'img/' + src.Settings.UI_ATLAS + '.json');
            this.game.load.atlas(src.Settings.FX_ATLAS, 'img/' + src.Settings.FX_ATLAS + '.png', 'img/' + src.Settings.FX_ATLAS + '.json');
            this.game.load.image('background1', 'img/backgrounds/background1.png');
            this.game.load.image('mainMenu', 'img/backgrounds/mainMenu.png');
            this.game.load.image('frame', 'img/backgrounds/frame.png');
            this.game.load.image('levels', 'img/backgrounds/levels.png');
            this.game.load.image('more_games', window.famobi.getMoreGamesButtonImage());
            if (this.game.device.desktop) {
            }
            else {
            }
        };
        Preloader.prototype.create = function () {
        };
        Preloader.prototype.onFileStart = function (progress, fileKey, fileURL) {
            if (src.Settings.ENABLE_PRELOADER_OUTPUT) {
                this.currentFileText.setText("" + fileURL);
            }
        };
        Preloader.prototype.onFileComplete = function (progress, cacheKey, success, totalLoaded, totalFiles) {
            this.preloaderBar.width = (progress * 0.95) / 100 * this.originalBarWidth;
            this.preloadText.setText("" + Phaser.Math.roundTo(progress * 0.95, 0) + "%");
        };
        Preloader.prototype.onLoadingComplete = function () {
            src.LocalStorageController.instance.loadSave();
            src.WindowManager.instance.init();
            src.LevelStorage.instance; //init level storage
            src.LevelManager.instance; //init level manager
            if (src.SoundController.instance.isDecodingSupported()) {
                this.game.sound.setDecodedCallback(this.soundNames, this.onSoundsDecoded, this);
            }
            else {
                this.onSoundsDecoded();
            }
        };
        Preloader.prototype.onSoundsDecoded = function () {
            this.preloaderBar.width = 1 * this.originalBarWidth;
            this.preloadText.setText("100%");
            src.WindowManager.instance.transitionTo("MainMenu");
        };
        Preloader.prototype.initSoundNames = function () {
            this.soundNames = [
                'coin_bonus',
                'pop',
                'gap_collapsing',
                'gap_bonus',
                'ball_inserting',
                'idol_mouth_opening',
                'idol_mouth_closing',
                'path_initialization',
                'bomb_explosion',
                'defeat_heartbeat',
                'scores_counting',
                'click',
                'swish_left',
                'swish_right',
                'ball_swap01',
                'ball_swap02',
                'fireball_picking_up',
                'fireball_shot',
                'shot01',
                'shot02',
                'rewind',
                'platform_change',
                'powerup_appearing',
                'lazer',
                'lighting',
                'victory',
                'ball_destroying',
                'torch_start',
                'torch_loop',
                'freezing',
                'unfreezing',
                'rolling_balls',
                'idol_hit_main_menu',
                'combo1',
                'combo2',
                'combo3',
                'combo4',
                'combo5',
                'combo6',
                'combo7',
                'combo8',
                'combo9',
                'combo10',
                'wheel',
                'themeA',
                'themeB',
                'themeC'
            ];
        };
        Preloader.prototype.enableDebugOutput = function () {
            var baseLogFunction = console.log;
            console.log = function () {
                baseLogFunction.apply(console, arguments);
                var args = Array.prototype.slice.call(arguments);
                for (var i = 0; i < args.length; i++) {
                    debugLog.push("" + args[i]);
                }
            };
            window.onerror = function (message, url, linenumber) {
                console.log("#JS error: " + message + " on line " + linenumber + " for " + url);
            };
        };
        Preloader.prototype.update = function () {
            if (src.Settings.ENABLE_PRELOADER_OUTPUT) {
                for (var _i = 0, debugLog_1 = debugLog; _i < debugLog_1.length; _i++) {
                    var line = debugLog_1[_i];
                    this.game.debug.text(line, 10, 10 + 15 * debugLog.indexOf(line), line.indexOf("#JS error") != -1 ? "#FF0000" : "#000000");
                }
            }
        };
        return Preloader;
    }(src.AutoResizeableState));
    src.Preloader = Preloader;
})(src || (src = {}));
var src;
(function (src) {
    var BaseTutorial = (function (_super) {
        __extends(BaseTutorial, _super);
        function BaseTutorial() {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.onCompleteCallback = null;
            _this.actionRadius = 10;
            _this.isActive = false;
            _this.buildSprites();
            return _this;
        }
        BaseTutorial.prototype.buildSprites = function () {
            this.circle = this.add(this.game.make.sprite(0, 8, src.Settings.FX_ATLAS, 'pointerAnim0000'));
            this.circle.anchor.set(0.5);
            this.circleRotationAnimation = this.circle.animations.add('circleRotation', Phaser.Animation.generateFrameNames('pointerAnim', 0, 13, '', 4), 30, true);
            this.hand = this.add(this.game.make.sprite(-10, -40, src.Settings.FX_ATLAS, 'tapAnim0000'));
            this.hand.anchor.set(0);
            this.tapAnimation = this.hand.animations.add('tapAnimation', Phaser.Animation.generateFrameNames('tapAnim', 0, 15, '', 4), 30, false);
            this.handInTween = this.game.add.tween(this.hand)
                .to({ x: -20, y: -35 }, 400, Phaser.Easing.Linear.None, false);
        };
        BaseTutorial.prototype.start = function () {
            var _this = this;
            this.stop();
            this.isActive = true;
            this.circleRotationAnimation.play();
            this.tapAnimation.onComplete.add(function () { return _this.delayEvent = _this.game.time.events.add(1000, function () { return _this.tapAnimation.play(); }); });
            this.handInTween.onComplete.addOnce(function () { return _this.tapAnimation.restart(); });
            this.hand.position.set(35, 30);
            this.alpha = 0;
            src.App.instance.add.tween(this)
                .to({ alpha: 1 }, 600, Phaser.Easing.Linear.None, true, 500)
                .onComplete.add(function () { return _this.handInTween.start(); });
        };
        BaseTutorial.prototype.stop = function () {
            this.isActive = false;
            this.circleRotationAnimation.stop();
            this.handInTween.onComplete.removeAll();
            this.tapAnimation.onComplete.removeAll();
            src.App.instance.time.events.remove(this.delayEvent);
            this.tapAnimation.stop(true);
        };
        BaseTutorial.prototype.completedHandler = function () {
            if (this.onCompleteCallback) {
                this.onCompleteCallback();
            }
            this.removeFromParent();
        };
        BaseTutorial.prototype.showAt = function (parent, onCompleteCallback) {
            this.onCompleteCallback = onCompleteCallback;
            parent.add(this);
            this.start();
        };
        BaseTutorial.prototype.dispatchToggleEvent = function (x, y) {
            var _this = this;
            if (Phaser.Math.distance(this.x, this.y, x, y) <= this.actionRadius) {
                src.App.instance.add.tween(this)
                    .to({ alpha: 0 }, 300, Phaser.Easing.Linear.None, true)
                    .onComplete.add(function () { return _this.completedHandler(); });
            }
        };
        BaseTutorial.prototype.removeFromParent = function () {
            this.onCompleteCallback = null;
            this.stop();
            if (this.parent) {
                this.parent.removeChild(this);
            }
        };
        BaseTutorial.prototype.destroy = function () {
            this.removeFromParent();
        };
        return BaseTutorial;
    }(Phaser.Group));
    src.BaseTutorial = BaseTutorial;
})(src || (src = {}));
///<reference path="BaseTutorial.ts"/>
var src;
(function (src) {
    var AimTutorial = (function (_super) {
        __extends(AimTutorial, _super);
        function AimTutorial(x, y) {
            var _this = _super.call(this) || this;
            _this.position.set(x, y);
            _this.actionRadius = 50;
            return _this;
        }
        AimTutorial.prototype.buildSprites = function () {
            this.circle = this.add(this.game.make.sprite(0, 8, src.Settings.FX_ATLAS, 'pointerAnim0000'));
            this.circle.anchor.set(0.5);
            this.circleRotationAnimation = this.circle.animations.add('circleRotation', Phaser.Animation.generateFrameNames('pointerAnim', 0, 13, '', 4), 30, true);
            this.hand = this.add(this.game.make.sprite(290 - 20, 5 - 35, src.Settings.FX_ATLAS, 'tapAnim0000'));
            this.hand.anchor.set(0);
            this.tapAnimation = this.hand.animations.add('tapAnimation', Phaser.Animation.generateFrameNames('tapAnim', 0, 7, '', 4), 30, false);
            this.releaseAnimation = this.hand.animations.add('releaseAnimation', Phaser.Animation.generateFrameNames('tapAnim', 7, 15, '', 4), 30, false);
            this.handInTween = this.game.add.tween(this.hand)
                .to({ x: -20, y: -35 }, 1600, Phaser.Easing.Linear.None, false);
        };
        AimTutorial.prototype.start = function () {
            var _this = this;
            this.stop();
            this.isActive = true;
            this.circleRotationAnimation.play();
            this.tapAnimation.onComplete.add(function () { return _this.delayEvent = _this.game.time.events.add(200, function () { return _this.handInTween.start(); }); });
            this.handInTween.onComplete.add(function () { return _this.releaseAnimation.restart(); });
            this.releaseAnimation.onComplete.add(function () { return _this.restartTweening(); });
            this.alpha = 0;
            src.App.instance.add.tween(this)
                .to({ alpha: 1 }, 750, Phaser.Easing.Linear.None, true, 200)
                .onComplete.add(function () { return _this.tapAnimation.play(); });
        };
        AimTutorial.prototype.stop = function () {
            this.isActive = false;
            this.circleRotationAnimation.stop();
            this.handInTween.onComplete.removeAll();
            this.tapAnimation.onComplete.removeAll();
            this.releaseAnimation.onComplete.removeAll();
            src.App.instance.time.events.remove(this.delayEvent);
            this.releaseAnimation.stop(true);
            this.tapAnimation.stop(true);
        };
        AimTutorial.prototype.completedHandler = function () {
            if (this.onCompleteCallback) {
                this.onCompleteCallback();
            }
            this.removeFromParent();
        };
        AimTutorial.prototype.restartTweening = function () {
            var _this = this;
            src.App.instance.add.tween(this.hand)
                .to({ alpha: 0 }, 400, Phaser.Easing.Linear.None, true, 500)
                .onComplete.add(function () {
                _this.hand.position.set(290 - 20, 5 - 35);
                src.App.instance.add.tween(_this.hand)
                    .to({ alpha: 1 }, 500, Phaser.Easing.Linear.None, true, 800)
                    .onComplete.add(function () { return _this.tapAnimation.restart(); });
            });
        };
        return AimTutorial;
    }(src.BaseTutorial));
    src.AimTutorial = AimTutorial;
})(src || (src = {}));
var src;
(function (src) {
    var ChangePlatformTutorial = (function (_super) {
        __extends(ChangePlatformTutorial, _super);
        function ChangePlatformTutorial(x, y) {
            var _this = _super.call(this) || this;
            _this.circle.scale.set(1.5);
            _this.position.set(x, y);
            _this.actionRadius = 50;
            return _this;
        }
        return ChangePlatformTutorial;
    }(src.BaseTutorial));
    src.ChangePlatformTutorial = ChangePlatformTutorial;
})(src || (src = {}));
var src;
(function (src) {
    var RotateWheelTutorial = (function (_super) {
        __extends(RotateWheelTutorial, _super);
        function RotateWheelTutorial(x, y) {
            var _this = _super.call(this) || this;
            _this.rotateRadius = 235;
            _this.startAngle = -Math.PI / 3;
            _this.endAngle = Math.PI / 3;
            _this.prevAngle = _this.startAngle;
            _this.currentAngle = _this.startAngle;
            _this.duration = 1100;
            _this.buildAdditionalSprites();
            _this.position.set(x, y);
            _this.actionRadius = 275;
            return _this;
        }
        RotateWheelTutorial.prototype.buildSprites = function () {
        };
        RotateWheelTutorial.prototype.buildAdditionalSprites = function () {
            var _this = this;
            this.initialPosition = new Phaser.Point(0, -this.rotateRadius);
            this.initialPosition.rotate(0, 0, this.startAngle);
            this.currentPosition = this.initialPosition.clone();
            this.hand = this.add(this.game.make.sprite(this.currentPosition.x - 20, this.currentPosition.y - 35, src.Settings.FX_ATLAS, 'tapAnim0000'));
            this.hand.scale.set(1.4);
            this.hand.anchor.set(0);
            this.tapAnimation = this.hand.animations.add('tapAnimation', Phaser.Animation.generateFrameNames('tapAnim', 0, 7, '', 4), 30, false);
            this.releaseAnimation = this.hand.animations.add('releaseAnimation', Phaser.Animation.generateFrameNames('tapAnim', 7, 15, '', 4), 30, false);
            this.handInTween = this.game.add.tween(this)
                .to({ currentAngle: this.endAngle }, this.duration, Phaser.Easing.Linear.None, false)
                .onUpdateCallback(function () { return _this.updateRotation(); });
        };
        RotateWheelTutorial.prototype.start = function () {
            var _this = this;
            this.stop();
            this.isActive = true;
            this.tapAnimation.onComplete.add(function () { return _this.delayEvent = _this.game.time.events.add(50, function () { return _this.handInTween.start(); }); });
            this.handInTween.onComplete.add(function () { return _this.releaseAnimation.restart(); });
            this.releaseAnimation.onComplete.add(function () { return _this.returnToStartPosition(); });
            this.alpha = 0;
            src.App.instance.add.tween(this)
                .to({ alpha: 1 }, 750, Phaser.Easing.Linear.None, true, 500)
                .onComplete.add(function () { return _this.tapAnimation.play(); });
        };
        RotateWheelTutorial.prototype.stop = function () {
            this.isActive = false;
            this.handInTween.onComplete.removeAll();
            this.tapAnimation.onComplete.removeAll();
            this.releaseAnimation.onComplete.removeAll();
            src.App.instance.time.events.remove(this.delayEvent);
            this.releaseAnimation.stop(true);
            this.tapAnimation.stop(true);
        };
        RotateWheelTutorial.prototype.updateRotation = function () {
            this.currentPosition = this.currentPosition.rotate(0, 0, this.currentAngle - this.prevAngle);
            this.hand.position.set(this.currentPosition.x - 20, this.currentPosition.y - 35);
            this.prevAngle = this.currentAngle;
        };
        RotateWheelTutorial.prototype.returnToStartPosition = function () {
            var _this = this;
            this.prevAngle = this.startAngle;
            this.currentAngle = this.startAngle;
            this.currentPosition = this.initialPosition.clone();
            src.App.instance.add.tween(this.hand)
                .to({ x: this.initialPosition.x - 20, y: this.initialPosition.y - 35 }, 500, Phaser.Easing.Linear.None, true, 150)
                .onComplete.add(function () { return _this.tapAnimation.restart(); });
        };
        return RotateWheelTutorial;
    }(src.BaseTutorial));
    src.RotateWheelTutorial = RotateWheelTutorial;
})(src || (src = {}));
var src;
(function (src) {
    var SwapBallsTutorial = (function (_super) {
        __extends(SwapBallsTutorial, _super);
        function SwapBallsTutorial(x, y) {
            var _this = _super.call(this) || this;
            _this.circle.scale.set(1.7);
            _this.hand.scale.set(1.3);
            _this.position.set(x, y);
            _this.actionRadius = 50;
            return _this;
        }
        return SwapBallsTutorial;
    }(src.BaseTutorial));
    src.SwapBallsTutorial = SwapBallsTutorial;
})(src || (src = {}));
var src;
(function (src) {
    var TapHereTutorial = (function (_super) {
        __extends(TapHereTutorial, _super);
        function TapHereTutorial(x, y) {
            var _this = _super.call(this) || this;
            _this.position.set(x, y);
            _this.actionRadius = 50;
            return _this;
        }
        return TapHereTutorial;
    }(src.BaseTutorial));
    src.TapHereTutorial = TapHereTutorial;
})(src || (src = {}));
var src;
(function (src) {
    var TutorialManager = (function (_super) {
        __extends(TutorialManager, _super);
        function TutorialManager() {
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.isFirstStageCompleted = false;
            _this.isSecondStageCompleted = false;
            _this.isWheelTutorialCompleted = false;
            _this.tapHereTutorialA = new src.TapHereTutorial(100, 300);
            _this.tapHereTutorialB = new src.TapHereTutorial(490, 180);
            _this.aimTutorial = new src.AimTutorial(200, 175);
            _this.swapBallsTutorial = new src.SwapBallsTutorial(312, 505);
            _this.changePlatformTutorialA = new src.ChangePlatformTutorial(381, 659);
            _this.changePlatformTutorialB = new src.ChangePlatformTutorial(268, 289);
            _this.wheelRotateTutorial = new src.RotateWheelTutorial(src.CustomScaleManager.ORIGINAL_WIDTH / 2 - 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 184);
            return _this;
        }
        Object.defineProperty(TutorialManager, "instance", {
            get: function () {
                return TutorialManager._instance ? TutorialManager._instance : TutorialManager._instance = new TutorialManager();
            },
            enumerable: true,
            configurable: true
        });
        /**
         * DISPATCHERS
         */
        TutorialManager.prototype.dispatchLevelStart = function (onCompleteCallback) {
            var _this = this;
            var currentState = src.App.instance.state.getCurrentState();
            if (currentState) {
                if (src.Settings.CURRENT_LEVEL == 1 && !this.isFirstStageCompleted) {
                    src.App.instance.state.getCurrentState().cannonManager.cannon.start();
                    if (this.game.device.desktop) {
                        this.tapHereTutorialA.showAt(currentState.container, function () { return _this.tapHereTutorialB.showAt(currentState.container, function () { return _this.swapBallsTutorial.showAt(currentState.container, function () { return _this.completedFirstStage(onCompleteCallback); }); }); });
                    }
                    else {
                        this.tapHereTutorialA.showAt(currentState.container, function () { return _this.tapHereTutorialB.showAt(currentState.container, function () { return _this.aimTutorial.showAt(currentState.container, function () { return _this.swapBallsTutorial.showAt(currentState.container, function () { return _this.completedFirstStage(onCompleteCallback); }); }); }); });
                    }
                }
                else if (src.Settings.CURRENT_LEVEL == 6 && !this.isSecondStageCompleted) {
                    src.App.instance.state.getCurrentState().cannonManager.cannon.start();
                    this.changePlatformTutorialA.showAt(currentState.container, function () { return _this.changePlatformTutorialB.showAt(currentState.container, function () { return _this.completedSecondStage(onCompleteCallback); }); });
                }
                else {
                    onCompleteCallback();
                }
            }
        };
        TutorialManager.prototype.dispatchLevelsMapOpening = function () {
            var _this = this;
            if (src.App.instance.state.getCurrentState() instanceof src.LevelsMap) {
                var currentState = src.App.instance.state.getCurrentState();
                if (src.Settings.LAST_UNLOCKED_LEVEL > 1 && !this.isWheelTutorialCompleted) {
                    this.wheelRotateTutorial.showAt(currentState.responsiveContainer, function () { return _this.completedWheelStage(); });
                }
            }
        };
        TutorialManager.prototype.dispatchShoot = function (targetPoint) {
            if (this.tapHereTutorialA.isActive) {
                this.tapHereTutorialA.dispatchToggleEvent(targetPoint.x, targetPoint.y);
            }
            if (this.tapHereTutorialB.isActive) {
                this.tapHereTutorialB.dispatchToggleEvent(targetPoint.x, targetPoint.y);
            }
            if (this.aimTutorial.isActive) {
                this.aimTutorial.dispatchToggleEvent(targetPoint.x, targetPoint.y);
            }
        };
        TutorialManager.prototype.dispatchBallsSwap = function (cannon) {
            if (this.swapBallsTutorial.isActive) {
                this.swapBallsTutorial.dispatchToggleEvent(cannon.x, cannon.y);
            }
        };
        TutorialManager.prototype.dispatchPlatformChange = function (platform) {
            if (this.changePlatformTutorialA.isActive) {
                this.changePlatformTutorialA.dispatchToggleEvent(platform.x, platform.y);
            }
            if (this.changePlatformTutorialB.isActive) {
                this.changePlatformTutorialB.dispatchToggleEvent(platform.x, platform.y);
            }
        };
        TutorialManager.prototype.dispatchWheelRotate = function (x, y) {
            if (this.wheelRotateTutorial.isActive) {
                this.wheelRotateTutorial.dispatchToggleEvent(x, y);
            }
        };
        TutorialManager.prototype.completedFirstStage = function (onCompleteCallback) {
            this.isFirstStageCompleted = true;
            src.LocalStorageController.instance.save();
            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_TUTORIALCOMPLETED);
            if (onCompleteCallback) {
                onCompleteCallback();
            }
        };
        TutorialManager.prototype.completedSecondStage = function (onCompleteCallback) {
            this.isSecondStageCompleted = true;
            src.LocalStorageController.instance.save();
            if (onCompleteCallback) {
                onCompleteCallback();
            }
        };
        TutorialManager.prototype.completedWheelStage = function () {
            this.isWheelTutorialCompleted = true;
            src.LocalStorageController.instance.save();
        };
        TutorialManager._instance = null;
        return TutorialManager;
    }(Phaser.Group));
    src.TutorialManager = TutorialManager;
})(src || (src = {}));
var src;
(function (src) {
    var AdvancedMath = (function () {
        function AdvancedMath() {
        }
        AdvancedMath.getDecimal = function (num) {
            return num % 1;
        };
        AdvancedMath.pointOnCircle = function (x, y, r) {
            var startAngle = 0;
            if (x - r * 1.5 < 0) {
                startAngle = 0.25;
            }
            else if (x + r * 1.5 > src.CustomScaleManager.ORIGINAL_WIDTH) {
                startAngle = 1.25;
            }
            else {
                startAngle = Math.random() > 0.5 ? 0.25 : 1.25;
            }
            var angle = Math.PI * (startAngle + Math.random() * 0.5) - Math.PI / 2;
            return new Phaser.Point(x + r * Math.cos(angle), y + r * Math.sin(angle));
        };
        AdvancedMath.pointOnSegment = function (x1, y1, x2, y2, distance) {
            var segmentLength = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
            if (segmentLength == 0) {
                return new Phaser.Point(x1, y1);
            }
            var point = new Phaser.Point();
            point.x = x1 + distance * (x2 - x1) / segmentLength;
            point.y = y1 + distance * (y2 - y1) / segmentLength;
            return point;
        };
        AdvancedMath.pointOnSegmentRelative = function (x1, y1, x2, y2, relativeDistance) {
            var segmentLength = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
            if (segmentLength == 0) {
                return new Phaser.Point(x1, y1);
            }
            var distance = segmentLength * relativeDistance;
            var point = new Phaser.Point();
            point.x = x1 + distance * (x2 - x1) / segmentLength;
            point.y = y1 + distance * (y2 - y1) / segmentLength;
            return point;
        };
        AdvancedMath.getRelativePosition = function (x1, y1, x2, y2, targetPoint) {
            var segmentLength = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1));
            if (segmentLength == 0) {
                return 0;
            }
            if (x2 != x1) {
                return (targetPoint.x - x1) * segmentLength / (x2 - x1) / segmentLength;
            }
            else if (y2 != y1) {
                return (targetPoint.y - y1) * segmentLength / (y2 - y1) / segmentLength;
            }
            else {
                return 0;
            }
        };
        AdvancedMath.findLineCircleIntersections = function (cx, cy, radius, segmentStartX, segmentStartY, segmentEndX, segmentEndY, closerToSegmentStart) {
            if (closerToSegmentStart === void 0) { closerToSegmentStart = true; }
            var dx, dy, A, B, C, det, t;
            dx = segmentEndX - segmentStartX;
            dy = segmentEndY - segmentStartY;
            A = dx * dx + dy * dy;
            B = 2 * (dx * (segmentStartX - cx) + dy * (segmentStartY - cy));
            C = (segmentStartX - cx) * (segmentStartX - cx) +
                (segmentStartY - cy) * (segmentStartY - cy) -
                radius * radius;
            det = B * B - 4 * A * C;
            if ((A <= 0.0000001) || (det < 0)) {
                // No real solutions.
                return null;
            }
            else if (det == 0) {
                // One solution.
                t = -B / (2 * A);
                var resultingPoint = new Phaser.Point(segmentStartX + t * dx, segmentStartY + t * dy);
                return AdvancedMath.checkPointBelongsToSegment(resultingPoint.x, resultingPoint.y, segmentStartX, segmentStartY, segmentEndX, segmentEndY) ? resultingPoint : null;
            }
            else {
                // Two solutions.
                t = ((-B + Math.sqrt(det)) / (2 * A));
                var p1 = new Phaser.Point(segmentStartX + t * dx, segmentStartY + t * dy);
                t = ((-B - Math.sqrt(det)) / (2 * A));
                var p2_1 = new Phaser.Point(segmentStartX + t * dx, segmentStartY + t * dy);
                p1 = AdvancedMath.checkPointBelongsToSegment(p1.x, p1.y, segmentStartX, segmentStartY, segmentEndX, segmentEndY) ? p1 : null;
                p2_1 = AdvancedMath.checkPointBelongsToSegment(p2_1.x, p2_1.y, segmentStartX, segmentStartY, segmentEndX, segmentEndY) ? p2_1 : null;
                if (p1 && p2_1) {
                    return (Phaser.Math.distance(segmentStartX, segmentStartY, p1.x, p1.y) <= Phaser.Math.distance(segmentStartX, segmentStartY, p2_1.x, p2_1.y)) ? (closerToSegmentStart ? p1 : p2_1) : (closerToSegmentStart ? p2_1 : p1);
                }
                else if (p1) {
                    return p1;
                }
                else if (p2_1) {
                    return p2_1;
                }
                else {
                    return null;
                }
            }
        };
        AdvancedMath.checkPointBelongsToSegment = function (px, py, startX, startY, endX, endY) {
            return (px >= Math.min(startX, endX) && px <= Math.max(startX, endX) && py >= Math.min(startY, endY) && py <= Math.max(startY, endY));
        };
        // Given three colinear points p, q, r, the function checks if
        // point q lies on line segment 'pr'
        AdvancedMath.onSegment = function (p, q, r) {
            if (q.x <= Math.max(p.x, r.x) && q.x >= Math.min(p.x, r.x) &&
                q.y <= Math.max(p.y, r.y) && q.y >= Math.min(p.y, r.y))
                return true;
            return false;
        };
        AdvancedMath.orientation = function (p, q, r) {
            var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
            if (val == 0)
                return 0;
            return (val > 0) ? 1 : 2;
        };
        AdvancedMath.testSegmentsIntersection = function (p1, q1, p2, q2) {
            var o1 = AdvancedMath.orientation(p1, q1, p2);
            var o2 = AdvancedMath.orientation(p1, q1, q2);
            var o3 = AdvancedMath.orientation(p2, q2, p1);
            var o4 = AdvancedMath.orientation(p2, q2, q1);
            // General case
            if (o1 != o2 && o3 != o4)
                return true;
            // Special Cases
            if (o1 == 0 && AdvancedMath.onSegment(p1, p2, q1))
                return true;
            if (o2 == 0 && AdvancedMath.onSegment(p1, q2, q1))
                return true;
            if (o3 == 0 && AdvancedMath.onSegment(p2, p1, q2))
                return true;
            if (o4 == 0 && AdvancedMath.onSegment(p2, q1, q2))
                return true;
            return false; // Doesn't fall in any of the above cases
        };
        AdvancedMath.CollisionDetector = (function () {
            function class_1() {
            }
            class_1.distanceBetween = function (vx, vy, wx, wy) {
                return (vx - wx) * (vx - wx) + (vy - wy) * (vy - wy);
            };
            class_1.distanceToSegmentSquared = function (px, py, vx, vy, wx, wy) {
                var l2 = AdvancedMath.CollisionDetector.distanceBetween(vx, vy, wx, wy);
                if (l2 == 0)
                    return AdvancedMath.CollisionDetector.distanceBetween(px, py, vx, vy);
                var t = ((px - vx) * (wx - vx) + (py - vy) * (wy - vy)) / l2;
                if (t < 0)
                    return AdvancedMath.CollisionDetector.distanceBetween(px, py, vx, vy);
                if (t > 1)
                    return AdvancedMath.CollisionDetector.distanceBetween(px, py, wx, wy);
                return AdvancedMath.CollisionDetector.distanceBetween(px, py, vx + t * (wx - vx), vy + t * (wy - vy));
            };
            class_1.getCollisionPoint = function (px, py, vx, vy, wx, wy) {
                var l2 = AdvancedMath.CollisionDetector.distanceBetween(vx, vy, wx, wy);
                if (l2 == 0)
                    return new Phaser.Point(vx, vy);
                var t = ((px - vx) * (wx - vx) + (py - vy) * (wy - vy)) / l2;
                if (t < 0)
                    return new Phaser.Point(vx, vy);
                if (t > 1)
                    return new Phaser.Point(wx, wy);
                return new Phaser.Point(vx + t * (wx - vx), vy + t * (wy - vy));
            };
            class_1.distanceToSegment = function (point, lineStart, lineEnd) {
                return Math.sqrt(AdvancedMath.CollisionDetector.distanceToSegmentSquared(point.x, point.y, lineStart.x, lineStart.y, lineEnd.x, lineEnd.y));
            };
            return class_1;
        }());
        return AdvancedMath;
    }());
    src.AdvancedMath = AdvancedMath;
})(src || (src = {}));
var src;
(function (src) {
    var BitmapTextFactory = (function () {
        function BitmapTextFactory() {
        }
        BitmapTextFactory.getComboText = function (comboMultiplier) {
            var group = new Phaser.Group(src.App.instance, null);
            var sourceText = 'X' + Math.floor(comboMultiplier);
            for (var i = 0; i < sourceText.length; i++) {
                var sprite = BitmapTextFactory.getLetter(sourceText.charAt(i));
                if (sprite) {
                    if (i == 0) {
                        sprite.x = sprite.width / 2;
                    }
                    else {
                        sprite.x = group.width + sprite.width / 2 + src.Settings.COMBO_TEXT_SPACING;
                    }
                    group.add(sprite);
                }
            }
            group.pivot.set(group.width / 2, 0);
            return group;
        };
        BitmapTextFactory.getScoreText = function (scores, color) {
            var group = new Phaser.Group(src.App.instance, null);
            var sourceText = '+' + Math.floor(scores);
            for (var i = 0; i < sourceText.length; i++) {
                var sprite = BitmapTextFactory.getLetter(sourceText.charAt(i), color);
                if (sprite) {
                    if (i == 0) {
                        sprite.x = sprite.width / 2;
                    }
                    else {
                        sprite.x = group.width + sprite.width / 2 + src.Settings.SCORE_TEXT_SPACING;
                    }
                    group.add(sprite);
                }
            }
            group.pivot.set(group.width / 2, 0);
            return group;
        };
        BitmapTextFactory.getLevelText = function (levelNumber, color) {
            var group = new Phaser.Group(src.App.instance, null);
            var sourceText = '' + Math.floor(levelNumber);
            for (var i = 0; i < sourceText.length; i++) {
                var sprite = BitmapTextFactory.getLetter(sourceText.charAt(i), color);
                if (sprite) {
                    if (i == 0) {
                        sprite.x = sprite.width / 2;
                    }
                    else {
                        sprite.x = group.width + sprite.width / 2 + src.Settings.SCORE_TEXT_SPACING;
                    }
                    group.add(sprite);
                }
            }
            group.pivot.set(group.width / 2, 0);
            return group;
        };
        BitmapTextFactory.getLetter = function (code, color) {
            if (color === void 0) { color = -1; }
            var spriteName = null;
            switch (code) {
                case 'X':
                    spriteName = 'textX' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '+':
                    spriteName = 'textPlus' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '1':
                    spriteName = 'text1' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '2':
                    spriteName = 'text2' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '3':
                    spriteName = 'text3' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '4':
                    spriteName = 'text4' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '5':
                    spriteName = 'text5' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '6':
                    spriteName = 'text6' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '7':
                    spriteName = 'text7' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '8':
                    spriteName = 'text8' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '9':
                    spriteName = 'text9' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
                case '0':
                    spriteName = 'text0' + '000' + BitmapTextFactory.getColorFrame(color);
                    break;
            }
            if (!spriteName) {
                return null;
            }
            var sprite = new Phaser.Sprite(src.App.instance, 0, 0, src.Settings.GAME_ATLAS, spriteName);
            sprite.anchor.setTo(0.5, 0.5);
            return sprite;
        };
        BitmapTextFactory.getColorFrame = function (color) {
            var frame = 0;
            switch (color) {
                case src.BallColor.BLACK:
                    frame = 8;
                    break;
                case src.BallColor.BLUE:
                    frame = 4;
                    break;
                case src.BallColor.GRAY:
                    frame = 7;
                    break;
                case src.BallColor.GREEN:
                    frame = 3;
                    break;
                case src.BallColor.PURPLE:
                    frame = 5;
                    break;
                case src.BallColor.CYAN:
                    frame = 6;
                    break;
                case src.BallColor.YELLOW:
                    frame = 2;
                    break;
                case src.BallColor.RED:
                    frame = 1;
                    break;
                default:
                    frame = 0;
            }
            return frame;
        };
        return BitmapTextFactory;
    }());
    src.BitmapTextFactory = BitmapTextFactory;
})(src || (src = {}));
var src;
(function (src) {
    var ButtonUtils = (function () {
        function ButtonUtils() {
        }
        ButtonUtils.createButton = function (atlasName, spriteName, x, y, callback, callbackContext) {
            var button = new Phaser.Button(src.App.instance, x, y, atlasName, callback, callbackContext, spriteName + '0001', spriteName + '0000', spriteName + '0002', spriteName + '0000');
            button.anchor.setTo(0.5, 0.5);
            button.input.pixelPerfectClick = true;
            button.input.useHandCursor = true;
            return button;
        };
        ButtonUtils.createSimpleButton = function (atlasName, spriteName, x, y, startScale, callback, callbackContext) {
            var button = new Phaser.Button(src.App.instance, x, y, atlasName, callback, callbackContext, spriteName + '0000', spriteName + '0000', spriteName + '0000', spriteName + '0000');
            button.anchor.setTo(0.5, 0.5);
            button.scale.set(startScale);
            button.input.pixelPerfectClick = true;
            button.input.useHandCursor = false;
            button["overTween"] = src.App.instance.add.tween(button.scale).to({ x: startScale * 1.05, y: startScale * 1.05 }, 100);
            button["outTween"] = src.App.instance.add.tween(button.scale).to({ x: startScale * 1.0, y: startScale * 1.0 }, 100);
            button["downTween"] = src.App.instance.add.tween(button.scale).to({ x: startScale * 0.95, y: startScale * 0.95 }, 50).to({ x: startScale * 1.0, y: startScale * 1.0 }, 50);
            button.events.onInputOver.add(ButtonUtils.mouseOverHandler, this, 0);
            button.events.onInputOut.add(ButtonUtils.mouseOutHandler, this, 0);
            button.events.onInputDown.add(ButtonUtils.mouseDownHandler, this, 0);
            return button;
        };
        ButtonUtils.mouseOverHandler = function (caller) {
            src.App.instance.add.tween(caller.scale).to({ x: 1.05 * src.CustomScaleManager.SCALE_X, y: 1.05 * src.CustomScaleManager.SCALE_Y }, 100).start();
        };
        ButtonUtils.mouseOutHandler = function (caller) {
            src.App.instance.add.tween(caller.scale).to({ x: 1.0 * src.CustomScaleManager.SCALE_X, y: 1.0 * src.CustomScaleManager.SCALE_Y }, 100).start();
        };
        ButtonUtils.mouseDownHandler = function (caller) {
            src.App.instance.add.tween(caller.scale).to({ x: 0.95 * src.CustomScaleManager.SCALE_X, y: 0.95 * src.CustomScaleManager.SCALE_Y }, 50).to({ x: 1.0 * src.CustomScaleManager.SCALE_X, y: 1.0 * src.CustomScaleManager.SCALE_Y }, 50).start();
        };
        return ButtonUtils;
    }());
    src.ButtonUtils = ButtonUtils;
})(src || (src = {}));
var src;
(function (src) {
    var CurveCalculator = (function () {
        function CurveCalculator() {
            this.len = 0;
            this.rPos = 0;
            this.res = [];
        }
        Object.defineProperty(CurveCalculator, "instance", {
            get: function () {
                return CurveCalculator._instance ? CurveCalculator._instance
                    : CurveCalculator._instance = new CurveCalculator();
            },
            enumerable: true,
            configurable: true
        });
        CurveCalculator.prototype.getCurvePointsClassic = function (points, tension, numSegments, close) {
            if (tension === void 0) { tension = 0.5; }
            if (numSegments === void 0) { numSegments = 25; }
            if (close === void 0) { close = false; }
            return getCurvePoints(points, tension, numSegments, close);
        };
        CurveCalculator.prototype.getCurvePoints = function (points, tension, close) {
            if (tension === void 0) { tension = 0.5; }
            if (close === void 0) { close = false; }
            if (!points || points.length < 2)
                return [];
            this.rPos = 0;
            this.res = [];
            this.len = points.length;
            var pts = points.slice(0);
            if (close) {
                pts.unshift(points[this.len - 1]); // insert end point as first point
                pts.unshift(points[this.len - 2]);
                pts.push(points[0], points[1]); // first point as last point
            }
            else {
                pts.unshift(points[1]); // copy 1. point and insert at beginning
                pts.unshift(points[0]);
                pts.push(points[this.len - 2], points[this.len - 1]); // duplicate end-points
            }
            this.parse(pts, this.len, tension);
            if (close) {
                pts = [];
                pts.push(points[this.len - 4], points[this.len - 3], points[this.len - 2], points[this.len - 1], // second last and last
                points[0], points[1], points[2], points[3]); // first and second
                this.parse(pts, 4, tension);
            }
            // add last point
            this.len = close ? 0 : points.length - 2;
            this.res[this.rPos++] = points[this.len++];
            this.res[this.rPos] = points[this.len];
            return this.res;
        };
        CurveCalculator.prototype.parse = function (pts, leng, tension) {
            for (var i = 2, t; i < leng; i += 2) {
                var pt1 = pts[i], pt2 = pts[i + 1], pt3 = pts[i + 2], pt4 = pts[i + 3], t1x = (pt3 - pts[i - 2]) * tension, t1y = (pt4 - pts[i - 1]) * tension, t2x = (pts[i + 4] - pt1) * tension, t2y = (pts[i + 5] - pt2) * tension, c = 0, c1, c2, c3, c4;
                var numSegments = Phaser.Math.distance(pt1, pt2, pt3, pt4) / CurveCalculator.DIVISOR;
                numSegments = numSegments < 1 ? 1 : Math.floor(numSegments);
                var cache = this.getCache(numSegments);
                for (t = 0; t < numSegments; t++) {
                    c1 = cache[c++];
                    c2 = cache[c++];
                    c3 = cache[c++];
                    c4 = cache[c++];
                    this.res[this.rPos++] = c1 * pt1 + c2 * pt3 + c3 * t1x + c4 * t2x;
                    this.res[this.rPos++] = c1 * pt2 + c2 * pt4 + c3 * t1y + c4 * t2y;
                }
            }
        };
        CurveCalculator.prototype.getCache = function (numOfSeq) {
            var cache = [];
            var cachePtr = 4;
            var i = 1;
            cache[0] = 1; // 1,0,0,0
            for (; i < numOfSeq; i++) {
                var st = i / numOfSeq, st2 = st * st, st3 = st2 * st, st23 = st3 * 2, st32 = st2 * 3;
                cache[cachePtr++] = st23 - st32 + 1; // c1
                cache[cachePtr++] = st32 - st23; // c2
                cache[cachePtr++] = st3 - 2 * st2 + st; // c3
                cache[cachePtr++] = st3 - st2; // c4
            }
            cache[++cachePtr] = 1;
            return cache;
        };
        CurveCalculator.DIVISOR = 10;
        return CurveCalculator;
    }());
    src.CurveCalculator = CurveCalculator;
})(src || (src = {}));
var src;
(function (src) {
    var LocalizationManager = (function () {
        function LocalizationManager() {
        }
        LocalizationManager.getText = function (key) {
            var translatedText = window.famobi.__(key);
            return translatedText ? translatedText : "NO_TRANSLATION_YET";
        };
        return LocalizationManager;
    }());
    src.LocalizationManager = LocalizationManager;
})(src || (src = {}));
var src;
(function (src) {
    var LocalStorageController = (function () {
        function LocalStorageController() {
            this.isLocalStorageSupported = false;
            this.data = null;
            window["famobi"] = window["famobi"] || {};
            window["famobi"].localStorage = window["famobi"].localStorage || window.localStorage;
            this.data = {
                "level": 1,
                "tutorialFirstStageCompleted": false,
                "tutorialSecondStageCompleted": false,
                "wheelTutorialCompleted": false,
                "wheelFirstTimeSpin": false,
                "scores": []
            };
            for (var i = 0; i < src.Settings.TOTAL_LEVELS + 1; i++) {
                this.data["scores"].push(0);
            }
        }
        Object.defineProperty(LocalStorageController, "instance", {
            get: function () {
                return LocalStorageController._instance ? LocalStorageController._instance
                    : LocalStorageController._instance = new LocalStorageController();
            },
            enumerable: true,
            configurable: true
        });
        LocalStorageController.prototype.getScores = function () {
            return this.data["scores"];
        };
        LocalStorageController.prototype.getLastUnlockedLevel = function () {
            return this.data["level"];
        };
        LocalStorageController.prototype.save = function () {
            this.data["scores"] = src.ScoreManager.instance.getScores();
            this.data["level"] = src.Settings.LAST_UNLOCKED_LEVEL;
            this.data["tutorialFirstStageCompleted"] = src.TutorialManager.instance.isFirstStageCompleted;
            this.data["tutorialSecondStageCompleted"] = src.TutorialManager.instance.isSecondStageCompleted;
            this.data["wheelTutorialCompleted"] = src.TutorialManager.instance.isWheelTutorialCompleted;
            this.data["wheelFirstTimeSpin"] = src.LevelsMap.firstTimeSpinned;
            if (this.isLocalStorageSupported) {
                window["famobi"].localStorage.setItem(src.Settings.STORAGE_NAME, JSON.stringify(this.data));
            }
        };
        LocalStorageController.prototype.checkLocalStorageSupported = function () {
            this.isLocalStorageSupported = true;
        };
        LocalStorageController.prototype.loadSave = function () {
            this.checkLocalStorageSupported();
            if (this.isLocalStorageSupported) {
                if (window["famobi"].localStorage.getItem(src.Settings.STORAGE_NAME)) {
                    this.data = JSON.parse(window["famobi"].localStorage.getItem(src.Settings.STORAGE_NAME));
                }
                else {
                    window["famobi"].localStorage.setItem(src.Settings.STORAGE_NAME, JSON.stringify(this.data));
                }
            }
            this.finalizeLoading();
        };
        LocalStorageController.prototype.finalizeLoading = function () {
            src.ScoreManager.instance.init(LocalStorageController.instance.getScores());
            src.Settings.LAST_UNLOCKED_LEVEL = LocalStorageController.instance.getLastUnlockedLevel();
            src.TutorialManager.instance.isFirstStageCompleted = this.data["tutorialFirstStageCompleted"];
            src.TutorialManager.instance.isSecondStageCompleted = this.data["tutorialSecondStageCompleted"];
            src.TutorialManager.instance.isWheelTutorialCompleted = this.data["wheelTutorialCompleted"] || false;
            src.LevelsMap.firstTimeSpinned = this.data["wheelFirstTimeSpin"] || false;
        };
        return LocalStorageController;
    }());
    src.LocalStorageController = LocalStorageController;
})(src || (src = {}));
var src;
(function (src) {
    var PlayerStatisticsCollector = (function () {
        function PlayerStatisticsCollector() {
            this.loses = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            this.balls = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            this.time = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            this.gaps = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            this.combos = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            this.coins = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            this.distanceToIdol = ['', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''];
        }
        Object.defineProperty(PlayerStatisticsCollector, "instance", {
            get: function () {
                return PlayerStatisticsCollector._instance ? PlayerStatisticsCollector._instance : PlayerStatisticsCollector._instance = new PlayerStatisticsCollector();
            },
            enumerable: true,
            configurable: true
        });
        PlayerStatisticsCollector.prototype.getUserStats = function () {
            var stats = "";
            for (var i = 1; i < src.Settings.TOTAL_LEVELS; i++) {
                if (this.time[i] > 0) {
                    stats +=
                        "============================== Level " + i + " =========================== \n                     Loses:     " + this.loses[i] + " \n                     Time:      " + src.TextUtils.convertMSToHumanTime(this.time[i]) + "\n                     Score:     " + src.LocalStorageController.instance.getScores()[i - 1] + "\n                     Balls:     " + this.balls[i] + "\n                     Gaps:      " + this.gaps[i] + "\n                     Combos:    " + this.combos[i] + "\n                     Coins:     " + this.coins[i] + "\n                     Idol in:   " + this.distanceToIdol[i] + " balls\n                     ";
                }
                else {
                    stats +=
                        "============================== Level " + i + " =========================== \n                     Loses:     " + this.loses[i] + " \n                     ";
                }
            }
            return stats;
        };
        PlayerStatisticsCollector._instance = null;
        return PlayerStatisticsCollector;
    }());
    src.PlayerStatisticsCollector = PlayerStatisticsCollector;
})(src || (src = {}));
var src;
(function (src) {
    var TextUtils = (function () {
        function TextUtils() {
        }
        TextUtils.addText = function (parent, text, x, y, fontSize, color, fontFamily, fontWidth) {
            if (fontFamily === void 0) { fontFamily = src.Settings.DEFAULT_FONT_FAMILY; }
            if (fontWidth === void 0) { fontWidth = null; }
            return parent.add(TextUtils.getText(text, x, y, fontSize, color, fontFamily, fontWidth));
        };
        TextUtils.getText = function (text, x, y, fontSize, color, fontFamily, fontWidth) {
            if (fontWidth === void 0) { fontWidth = null; }
            var textField = new Phaser.Text(src.App.instance, x, y, text, {
                font: (fontWidth ? fontWidth + ' ' : '') + fontSize + fontFamily,
                fill: color,
                align: "center"
            });
            textField.anchor.setTo(0.5, 0.5);
            return textField;
        };
        TextUtils.getShadowText = function (text, x, y, fontSize, color, shadowColor, shadowX, shadowY, anchorX, anchorY, fontFamily, fontWidth) {
            if (shadowColor === void 0) { shadowColor = "#000000"; }
            if (shadowX === void 0) { shadowX = 0; }
            if (shadowY === void 0) { shadowY = 2; }
            if (anchorX === void 0) { anchorX = 0.5; }
            if (anchorY === void 0) { anchorY = 0.5; }
            if (fontFamily === void 0) { fontFamily = src.Settings.DEFAULT_FONT_FAMILY; }
            if (fontWidth === void 0) { fontWidth = null; }
            var textField = new Phaser.Text(src.App.instance, x, y, text, {
                font: (fontWidth ? fontWidth + ' ' : '') + fontSize + fontFamily,
                fill: color,
                align: "center"
            });
            textField.anchor.setTo(anchorX, anchorY);
            textField.setShadow(shadowX, shadowY, shadowColor, 0);
            return textField;
        };
        TextUtils.getStyledText = function (text, x, y, fontSize, color, strokeColor, strokeThinkness, fontFamily, fontWidth) {
            if (strokeThinkness === void 0) { strokeThinkness = 4; }
            if (fontFamily === void 0) { fontFamily = src.Settings.DEFAULT_FONT_FAMILY; }
            if (fontWidth === void 0) { fontWidth = null; }
            var textField = new Phaser.Text(src.App.instance, x, y, text, {
                font: (fontWidth ? fontWidth + ' ' : '') + fontSize + fontFamily,
                fill: color,
                stroke: strokeColor,
                strokeThickness: strokeThinkness,
                align: "center"
            });
            textField.setShadow(0, 2, strokeColor, 0);
            textField.anchor.set(0.5, 0.5);
            return textField;
        };
        TextUtils.convertMSToHumanTime = function (milliseconds) {
            var seconds = Math.floor(milliseconds / 1000);
            var minutes = Math.floor(seconds / 60);
            var restSeconds = seconds - minutes * 60;
            return (minutes < 10 ? "0" : "") + minutes + ":" + (restSeconds < 10 ? "0" : "") + restSeconds;
        };
        return TextUtils;
    }());
    src.TextUtils = TextUtils;
})(src || (src = {}));
var src;
(function (src) {
    var BaseWindow = (function (_super) {
        __extends(BaseWindow, _super);
        function BaseWindow(regX, regY, backgroundAlpha) {
            if (backgroundAlpha === void 0) { backgroundAlpha = src.Settings.WINDOW_BACKGROUND_ALPHA; }
            var _this = _super.call(this, src.App.instance, null) || this;
            _this.backgroundAlpha = src.Settings.WINDOW_BACKGROUND_ALPHA;
            _this.registrationPoint = new Phaser.Point(regX, regY);
            _this.backgroundAlpha = backgroundAlpha;
            _this.visible = false;
            _this.buildBackground();
            _this.buildContent();
            return _this;
        }
        BaseWindow.prototype.buildBackground = function () {
            this.background = this.add(this.game.make.graphics(0, 0));
            this.background.beginFill(0x000000, src.Settings.WINDOW_BACKGROUND_ALPHA).drawRect(0, 0, this.game.world.width, this.game.world.height).endFill();
            this.background.inputEnabled = true;
        };
        BaseWindow.prototype.buildContent = function () {
            this.content = this.game.make.group(this);
            this.content.inputEnableChildren = true;
        };
        BaseWindow.prototype.resize = function () {
            this.background.clear().beginFill(0x000000, this.backgroundAlpha).drawRect(0, 0, this.game.world.width, this.game.world.height).endFill();
            this.content.scale.set(src.CustomScaleManager.SCALE_X, src.CustomScaleManager.SCALE_Y);
            this.content.position.set(src.CustomScaleManager.WIDTH / 2 - src.CustomScaleManager.ORIGINAL_WIDTH * src.CustomScaleManager.SCALE_X / 2, src.CustomScaleManager.HEIGHT / 2 - src.CustomScaleManager.ORIGINAL_HEIGHT * src.CustomScaleManager.SCALE_Y / 2);
        };
        BaseWindow.prototype.show = function () {
            this.visible = true;
            this.resize();
            this.game.stage.addChild(this);
        };
        BaseWindow.prototype.hide = function () {
            this.visible = false;
            if (this.parent) {
                this.parent.removeChild(this);
            }
        };
        BaseWindow.prototype.lockUpButtons = function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            for (var i = 0; i < args.length; i++) {
                args[i]["inputEnabled"] = false;
            }
        };
        BaseWindow.prototype.unlockButtons = function () {
            var args = [];
            for (var _i = 0; _i < arguments.length; _i++) {
                args[_i] = arguments[_i];
            }
            for (var i = 0; i < args.length; i++) {
                args[i]["inputEnabled"] = true;
            }
        };
        BaseWindow.prototype.destroy = function () {
            _super.prototype.destroy.call(this);
            this.background = null;
            this.content = null;
        };
        return BaseWindow;
    }(Phaser.Group));
    src.BaseWindow = BaseWindow;
})(src || (src = {}));
var src;
(function (src) {
    var CreditsWindow = (function (_super) {
        __extends(CreditsWindow, _super);
        function CreditsWindow() {
            return _super.call(this, src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 240, 0.9) || this;
        }
        CreditsWindow.prototype.buildContent = function () {
            _super.prototype.buildContent.call(this);
            this.buttonHome = this.content.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonHomeLevels', src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 240 + 55, this.homeClicked, this));
            this.plateContainer = this.content.add(this.game.make.group(null));
            this.plateContainer.position.copyFrom(this.registrationPoint);
            this.creditsPlate = this.plateContainer.add(this.game.make.sprite(0, -290, src.Settings.UI_ATLAS, 'creditsPlate' + '0000'));
            this.creditsPlate.anchor.set(0.5);
            this.textProduced = this.plateContainer.add(src.TextUtils.getShadowText(src.LocalizationManager.getText("txt_produced_and_published"), -164, -392, 32, "#FFFFFF", "#331E2D", 0, 5));
            this.textProduced.anchor.set(0, 0.5);
            this.textDeveloped = this.plateContainer.add(src.TextUtils.getShadowText(src.LocalizationManager.getText("txt_developed"), -160, -229, 32, "#FFFFFF", "#331E2D", 0, 5));
            this.textDeveloped.anchor.set(0, 0.5);
        };
        CreditsWindow.prototype.show = function () {
            _super.prototype.show.call(this);
            this.clearTweens();
            this.background.alpha = 0;
            this.game.add.tween(this.background)
                .to({ alpha: 1 }, 300, Phaser.Easing.Circular.Out, true, 0);
            this.plateContainer.alpha = 0;
            this.plateContainer.scale.set(0);
            this.game.add.tween(this.plateContainer)
                .to({ alpha: 1 }, 400, Phaser.Easing.Circular.Out, true, 100);
            this.game.add.tween(this.plateContainer.scale)
                .to({ x: 1, y: 1 }, 400, Phaser.Easing.Back.Out, true, 100);
            this.buttonHome.scale.set(0.5);
            this.buttonHome.alpha = 0;
            this.game.add.tween(this.buttonHome)
                .to({ alpha: 1 }, 350, Phaser.Easing.Cubic.Out, true, 400);
            this.game.add.tween(this.buttonHome.scale)
                .to({ x: 1, y: 1 }, 350, Phaser.Easing.Back.Out, true, 400);
            window.famobi_analytics.trackScreen(window.famobi_analytics.SCREEN_CREDITS);
        };
        CreditsWindow.prototype.clearTweens = function () {
            this.game.tweens.removeFrom(this.background);
            this.game.tweens.removeFrom(this.plateContainer);
            this.game.tweens.removeFrom(this.plateContainer.scale);
        };
        CreditsWindow.prototype.hide = function () {
            this.clearTweens();
            _super.prototype.hide.call(this);
        };
        CreditsWindow.prototype.homeClicked = function () {
            this.game.sound.play('click', 0.9);
            this.hide();
        };
        return CreditsWindow;
    }(src.BaseWindow));
    src.CreditsWindow = CreditsWindow;
})(src || (src = {}));
var src;
(function (src) {
    var DefeatWindow = (function (_super) {
        __extends(DefeatWindow, _super);
        function DefeatWindow() {
            return _super.call(this, src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 240) || this;
        }
        DefeatWindow.prototype.buildContent = function () {
            _super.prototype.buildContent.call(this);
            this.heartbeatSound = this.game.add.sound('defeat_heartbeat', 0.9, false);
            this.defeatCrossLeft = this.content.add(this.game.make.sprite(this.registrationPoint.x - 15, this.registrationPoint.y - 280, src.Settings.UI_ATLAS, 'defeatCrossLeft' + '0000'));
            this.defeatCrossLeft.anchor.set(0.5);
            this.defeatCrossLeft.angle = -60;
            this.defeatCrossLeftAnimation = this.defeatCrossLeft.animations.add('crossAnimation', Phaser.Animation.generateFrameNames('defeatCrossLeft', 0, 8, '', 4));
            this.defeatCrossRight = this.content.add(this.game.make.sprite(this.registrationPoint.x, this.registrationPoint.y - 300, src.Settings.UI_ATLAS, 'defeatCrossRight' + '0000'));
            this.defeatCrossRight.anchor.set(0.5);
            this.defeatCrossRight.angle = 60;
            this.defeatCrossRightAnimation = this.defeatCrossRight.animations.add('crossAnimation', Phaser.Animation.generateFrameNames('defeatCrossRight', 0, 6, '', 4));
            this.totemHead = this.content.add(this.game.make.sprite(this.registrationPoint.x, this.registrationPoint.y - 285, src.Settings.UI_ATLAS, 'defeatTotem' + '0000'));
            this.totemHead.anchor.set(0.5);
            this.buttonsContainer = this.content.add(this.game.make.group(null));
            this.buttonsContainer.position.copyFrom(this.registrationPoint);
            this.buttonsFrame = this.buttonsContainer.add(this.game.make.sprite(0, 0, src.Settings.UI_ATLAS, 'pauseFrame' + '0000'));
            this.buttonsFrame.anchor.set(0.5);
            this.buttonHome = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonHomeGray', -162, 0, this.homeClicked, this));
            this.buttonRestart = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonRestartRed', 0, 0, this.restartClicked, this));
            this.buttonSoundOn = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonSoundOnGray', 162, 0, this.soundOnClicked, this));
            this.buttonSoundOff = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonSoundOffGray', 162, 0, this.soundOffClicked, this));
        };
        DefeatWindow.prototype.show = function () {
            var _this = this;
            _super.prototype.show.call(this);

            window.famobi_analytics.trackScreen(window.famobi_analytics.SCREEN_LEVELRESULT);

            this.buttonHome.visible = false;
            this.buttonRestart.visible = false;
            this.buttonSoundOn.visible = false;
            this.buttonSoundOff.visible = false;
            this.buttonsContainer.visible = false;

            src.PlayerStatisticsCollector.instance.loses[src.Settings.CURRENT_LEVEL] += 1;
            src.SoundController.instance.chokeMusicVolume();
            this.clearTweens();
            this.buttonsContainer.alpha = 0;
            this.buttonsContainer.scale.set(0);
            this.totemHead.alpha = 0;
            this.background.alpha = 0;
            this.game.add.tween(this.background)
                .to({ alpha: 1 }, 800, Phaser.Easing.Circular.Out, true, 0);
            this.game.time.events.add(500, function () { return _this.defeatCrossLeftAnimation.play(20, false).onComplete.add(function () { return _this.defeatCrossRightAnimation.play(15, false); }); });
            this.game.add.tween(this.buttonsContainer)
                .to({ alpha: 1 }, 350, Phaser.Easing.Circular.Out, true, 1600);
            this.game.add.tween(this.buttonsContainer.scale)
                .to({ x: 1, y: 1 }, 350, Phaser.Easing.Back.Out, true, 1600);
            this.game.add.tween(this.totemHead)
                .to({ alpha: 1 }, 350, Phaser.Easing.Linear.None, true, 2100).onComplete.add(function () { return _this.startTotemHeadAnimations(); });
            this.game.time.events.add(360, function () { return _this.game.sound.play('swish_left', 0.9); });
            this.game.time.events.add(820, function () { return _this.game.sound.play('swish_right', 0.9); });
        };
        DefeatWindow.prototype.startTotemHeadAnimations = function () {
            var _this = this;
            this.game.tweens.removeFrom(this.totemHead.scale);
            var scaleUpTween = this.game.add.tween(this.totemHead.scale)
                .to({ x: 1.12, y: 1.12 }, 210, Phaser.Easing.Back.Out, true, 0);
            var scaleUpTween2 = this.game.add.tween(this.totemHead.scale)
                .to({ x: 1.16, y: 1.16 }, 210, Phaser.Easing.Back.InOut, false, 0);
            var scaleDownTween = this.game.add.tween(this.totemHead.scale)
                .to({ x: 1, y: 1 }, 1100, Phaser.Easing.Linear.None, false, 0);
            scaleUpTween.chain(scaleUpTween2);
            scaleUpTween2.chain(scaleDownTween);
            scaleDownTween.chain(scaleUpTween);
            scaleUpTween.onStart.add(function () {
                return _this.heartbeatSound.play();
            });

            var showButtons = function() {
                this.buttonsContainer.visible = true;
                this.buttonHome.visible = true;
                this.buttonRestart.visible = true;
                this.unlockButtons(this.buttonHome, this.buttonRestart, this.buttonSoundOn, this.buttonSoundOff);
                this.updateSoundButtons();

            }.bind(this);

            setTimeout(function() {
                Promise.all([
                    window.famobi_analytics.trackEvent("EVENT_LEVELFAIL", {
                        levelName: "" + src.Settings.CURRENT_LEVEL,
                        reason: "dead"
                    })
                    ]).then(showButtons, showButtons);
            }, 1500);
        };
        DefeatWindow.prototype.clearTweens = function () {
            this.defeatCrossLeftAnimation.stop(true);
            this.defeatCrossRightAnimation.stop(true);
            this.game.tweens.removeFrom(this.background);
            this.game.tweens.removeFrom(this.buttonsContainer);
            this.game.tweens.removeFrom(this.buttonsContainer.scale);
            this.game.tweens.removeFrom(this.totemHead.scale);
        };
        DefeatWindow.prototype.hide = function () {
            src.SoundController.instance.restoreMusicVolume();
            _super.prototype.hide.call(this);
            this.clearTweens();
        };
        DefeatWindow.prototype.homeClicked = function () {
            var _this = this;
            this.lockUpButtons(this.buttonHome, this.buttonRestart, this.buttonSoundOn, this.buttonSoundOff);
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.transitionTo('MainMenu', function () { return _this.hide(); });
            src.App.instance.showAd(50);
        };
        DefeatWindow.prototype.restartClicked = function () {
            var _this = this;
            this.lockUpButtons(this.buttonHome, this.buttonRestart, this.buttonSoundOn, this.buttonSoundOff);
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.transitionTo('Level', function () { return _this.hide(); });
            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_LEVELRESTART, {
                levelName: '' + src.Settings.CURRENT_LEVEL
            });
            src.App.instance.showAd(50);
        };
        DefeatWindow.prototype.soundOnClicked = function () {
            this.game.sound.mute = true;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);

            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                bgmVolume: 0.0,
                sfxVolume: 0.0
            });
            window.famobi.localStorage.setItem("muted", true);
        };
        DefeatWindow.prototype.soundOffClicked = function () {
            this.game.sound.mute = false;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);

            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                bgmVolume: 1.0,
                sfxVolume: 1.0
            });
            window.famobi.localStorage.removeItem("muted");
        };
        /**
         * STATE HANDLERS
         */
        DefeatWindow.prototype.updateSoundButtons = function () {

            if(typeof window.famobi.audio == "undefined" || window.famobi.audio.hasControls()){
                if (this.game.sound.mute) {
                    this.buttonSoundOn.visible = false;
                    this.buttonSoundOff.visible = true;
                }
                else {
                    this.buttonSoundOn.visible = true;
                    this.buttonSoundOff.visible = false;
                }
            }
            else{
                this.buttonSoundOn.visible = false;
                this.buttonSoundOff.visible = false;
            }
        };
        return DefeatWindow;
    }(src.BaseWindow));
    src.DefeatWindow = DefeatWindow;
})(src || (src = {}));
var src;
(function (src) {
    var PauseWindow = (function (_super) {
        __extends(PauseWindow, _super);
        function PauseWindow() {
            return _super.call(this, src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 240) || this;
        }
        PauseWindow.prototype.buildContent = function () {
            _super.prototype.buildContent.call(this);
            this.sandClock = this.content.add(this.game.make.sprite(this.registrationPoint.x, this.registrationPoint.y - 290, src.Settings.UI_ATLAS, 'sandClock' + '0000'));
            this.sandClock.scale.set(1.3);
            this.sandClock.anchor.set(0.5);
            this.buttonsContainer = this.content.add(this.game.make.group(null));
            this.buttonsContainer.position.copyFrom(this.registrationPoint);
            this.buttonsFrame = this.buttonsContainer.add(this.game.make.sprite(0, 0, src.Settings.UI_ATLAS, 'pauseFrame' + '0000'));
            this.buttonsFrame.anchor.set(0.5);
            this.buttonHome = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonHomeGray', -162, 0, this.homeClicked, this));
            this.buttonResume = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonResumeYellow', 0, 0, this.resumeClicked, this));
            this.buttonSoundOn = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonSoundOnGray', 162, 0, this.soundOnClicked, this));
            this.buttonSoundOff = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonSoundOffGray', 162, 0, this.soundOffClicked, this));
            this.buttonResumeShining = this.buttonsContainer.add(this.game.make.sprite(0, 0, src.Settings.UI_ATLAS, 'buttonShining' + '0000'));
            this.buttonResumeShining.anchor.set(0.5);
            this.buttonResumeShining.scale.set(2);
            this.buttonResumeShining.angle = 45;
            this.buttonResumeShining.animations.add('shining', Phaser.Animation.generateFrameNames('buttonShining', 0, 99, '', 4).concat(Phaser.Animation.generateFrameNames('buttonShining', 0, 99, '', 4).reverse()));
            this.buttonResumeShining.animations.play('shining', 60, true);
        };
        PauseWindow.prototype.show = function () {
            _super.prototype.show.call(this);
            this.unlockButtons(this.buttonHome, this.buttonResume, this.buttonSoundOn, this.buttonSoundOff);
            this.updateSoundButtons();
            src.SoundController.instance.chokeMusicVolume();

            this.clearTweens();
            this.buttonsContainer.alpha = 0;
            this.buttonsContainer.scale.set(0);
            this.background.alpha = 0;
            this.game.add.tween(this.background)
                .to({ alpha: 1 }, 300, Phaser.Easing.Circular.Out, true, 0);
            this.game.add.tween(this.buttonsContainer)
                .to({ alpha: 1 }, 200, Phaser.Easing.Circular.Out, true, 100);
            this.game.add.tween(this.buttonsContainer.scale)
                .to({ x: 1, y: 1 }, 200, Phaser.Easing.Back.Out, true, 100);
            this.sandClock.scale.set(0);
            this.game.add.tween(this.sandClock.scale)
                .to({ x: 1.3, y: 1.3 }, 200, Phaser.Easing.Sinusoidal.InOut, true, 100)
                .onComplete.add(this.startSandClockShakingAnimation, this);
            src.App.instance.showAd(50);
        };
        PauseWindow.prototype.startSandClockShakingAnimation = function () {
            this.sandClock.scale.set(1.3);
            this.game.add.tween(this.sandClock.scale)
                .to({ x: 1.2, y: 1.2 }, 1900, Phaser.Easing.Sinusoidal.InOut, true, 0, -1, true);
            var shakeTween = this.game.add.tween(this.sandClock)
                .to({ rotation: Phaser.Math.degToRad(5) }, 50, Phaser.Easing.Sinusoidal.InOut, true, 0, 2, true);
            var waitingTween = this.game.add.tween(this.sandClock)
                .to({}, 1500, Phaser.Easing.Linear.None, false, 0);
            shakeTween.chain(waitingTween);
            waitingTween.chain(shakeTween);
        };
        PauseWindow.prototype.clearTweens = function () {
            this.game.tweens.removeFrom(this.background);
            this.game.tweens.removeFrom(this.buttonsContainer);
            this.game.tweens.removeFrom(this.buttonsContainer.scale);
            this.game.tweens.removeFrom(this.sandClock);
            this.game.tweens.removeFrom(this.sandClock.scale);
        };
        PauseWindow.prototype.hide = function () {
            src.SoundController.instance.restoreMusicVolume();
            this.clearTweens();
            _super.prototype.hide.call(this);
        };
        PauseWindow.prototype.homeClicked = function () {
            var _this = this;
            this.lockUpButtons(this.buttonHome, this.buttonResume, this.buttonSoundOn, this.buttonSoundOff);
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.transitionTo('MainMenu', function () { return _this.hide(); });
            setTimeout(function () {
                window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_LEVELFAIL, {
                    levelName: '' + src.Settings.CURRENT_LEVEL,
                    reason: 'quit'
                });
            }, 100);
            src.App.instance.showAd(50);
        };
        PauseWindow.prototype.resumeClicked = function () {
            this.game.sound.play('click', 0.9);
            this.hide();
            if (this.game.state.getCurrentState() instanceof src.Level) {
                this.game.state.getCurrentState().gameStateManager.resumeLevel();
            }
            src.App.instance.showAd(50);
        };
        PauseWindow.prototype.soundOnClicked = function () {
            this.game.sound.mute = true;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);

            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                bgmVolume: 0.0,
                sfxVolume: 0.0
            });
            window.famobi.localStorage.setItem("muted", true);
        };
        PauseWindow.prototype.soundOffClicked = function () {
            this.game.sound.mute = false;
            this.updateSoundButtons();
            this.game.sound.play('click', 0.9);

            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_VOLUMECHANGE, {
                bgmVolume: 1.0,
                sfxVolume: 1.0
            });
            window.famobi.localStorage.removeItem("muted");
        };
        PauseWindow.prototype.updateSoundButtons = function () {

            if(typeof window.famobi.audio == "undefined" || window.famobi.audio.hasControls()){
                if (this.game.sound.mute) {
                    this.buttonSoundOn.visible = false;
                    this.buttonSoundOff.visible = true;
                }
                else {
                    this.buttonSoundOn.visible = true;
                    this.buttonSoundOff.visible = false;
                }
            }
            else{
                this.buttonSoundOn.visible = false;
                this.buttonSoundOff.visible = false;
            }


        };
        return PauseWindow;
    }(src.BaseWindow));
    src.PauseWindow = PauseWindow;
})(src || (src = {}));
var src;
(function (src) {
    var ResultsWindow = (function (_super) {
        __extends(ResultsWindow, _super);
        function ResultsWindow() {
            return _super.call(this, src.CustomScaleManager.ORIGINAL_WIDTH / 2, src.CustomScaleManager.ORIGINAL_HEIGHT / 2 + 240, 0.9) || this;
        }
        ResultsWindow.prototype.buildContent = function () {
            _super.prototype.buildContent.call(this);
            this.mainContainer = this.content.add(this.game.make.group(null));
            this.mainContainer.position.copyFrom(this.registrationPoint);
            this.buildButtons();
            this.buildTotem();
            this.buildBoard();
        };
        ResultsWindow.prototype.buildButtons = function () {
            this.buttonsContainer = this.mainContainer.add(this.game.make.group(null));
            this.buttonsFrame = this.buttonsContainer.add(this.game.make.sprite(0, 0, src.Settings.UI_ATLAS, 'resultsFrame' + '0000'));
            this.buttonsFrame.anchor.set(0.5);
            this.buttonHome = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonHomeGray', -162, 13, this.homeClicked, this));
            this.buttonNext = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonNextYellow', 1, 13, this.nextClicked, this));
            this.buttonRestart = this.buttonsContainer.add(src.ButtonUtils.createButton(src.Settings.UI_ATLAS, 'buttonRestartGray', 162, 13, this.restartClicked, this));
            this.buttonNextShining = this.buttonsContainer.add(this.game.make.sprite(0, 13, src.Settings.UI_ATLAS, 'buttonShining' + '0000'));
            this.buttonNextShining.anchor.set(0.5);
            this.buttonNextShining.scale.set(2);
            this.buttonNextShining.angle = 45;
            this.buttonNextShining.animations.add('shining', Phaser.Animation.generateFrameNames('buttonShining', 0, 99, '', 4).concat(Phaser.Animation.generateFrameNames('buttonShining', 0, 99, '', 4).reverse()));
            this.buttonNextShining.animations.play('shining', 60, true);

            this.buttonNext.visible = false;
            this.buttonHome.visible = false;
            this.buttonRestart.visible = false;
            this.buttonNextShining.visible = false;
        };
        ResultsWindow.prototype.buildBoard = function () {
            var _this = this;
            this.boardContainer = this.mainContainer.add(this.game.make.group(null));
            this.boardContainer.position.set(0, -217);
            this.fireLeft = this.boardContainer.add(this.game.make.sprite(-195, -10, src.Settings.FX_ATLAS, 'fire' + '0000'));
            this.fireLeft.anchor.set(0.5, 1);
            this.fireLeftStartAnimation = this.fireLeft.animations.add('fireStart', Phaser.Animation.generateFrameNames('fire', 0, 59, '', 4), 40, false);
            this.fireLeftCycledAnimation = this.fireLeft.animations.add('fire', Phaser.Animation.generateFrameNames('fire', 60, 64, '', 4).concat(Phaser.Animation.generateFrameNames('fire', 39, 59, '', 4)), 40, true);
            this.fireLeftStartAnimation.onComplete.add(function () { return _this.fireLeftCycledAnimation.play(); });
            this.monkeyLeft = this.boardContainer.add(this.game.make.sprite(-197, 138, src.Settings.UI_ATLAS, 'monkeyTotem' + '0000'));
            this.monkeyLeft.anchor.set(0.5, 1);
            this.fireRight = this.boardContainer.add(this.game.make.sprite(200, -10, src.Settings.FX_ATLAS, 'fire' + '0000'));
            this.fireRight.anchor.set(0.5, 1);
            this.fireRightStartAnimation = this.fireRight.animations.add('fireStart', Phaser.Animation.generateFrameNames('fire', 0, 59, '', 4), 40, false);
            this.fireRightCycledAnimation = this.fireRight.animations.add('fire', Phaser.Animation.generateFrameNames('fire', 60, 64, '', 4).concat(Phaser.Animation.generateFrameNames('fire', 39, 59, '', 4)), 40, true);
            this.fireRightStartAnimation.onComplete.add(function () { return _this.fireRightCycledAnimation.play(); });
            this.monkeyRight = this.boardContainer.add(this.game.make.sprite(197, 138, src.Settings.UI_ATLAS, 'monkeyTotem' + '0000'));
            this.monkeyRight.anchor.set(0.5, 1);
            this.torchStartSound = this.game.add.sound('torch_start', 1);
            this.torchLoopSound = this.game.add.sound('torch_loop', 1, true);
            this.board = this.boardContainer.add(new src.ResultsBoard());
        };
        ResultsWindow.prototype.buildTotem = function () {
            this.totemContainer = this.mainContainer.add(this.game.make.group(null));
            this.totemContainer.position.set(0, -374);
            this.leafsAnimation = this.totemContainer.add(new src.LeafsAnimation(0, 0));
            this.feathersAnimation = this.totemContainer.add(new src.FeathersAnimation(0, 0));
            this.monkeyTop = this.totemContainer.add(this.game.make.sprite(0, 0, src.Settings.UI_ATLAS, 'resultsTotem' + '0000'));
            this.monkeyTop.anchor.set(0.5, 1);
        };
        ResultsWindow.prototype.show = function () {
            var _this = this;
            _super.prototype.show.call(this);
            this.unlockButtons(this.buttonHome, this.buttonNext, this.buttonRestart);
            src.SoundController.instance.chokeMusicVolume(100);
            this.game.sound.play('victory', 0.8);
            this.clearTweens();
            this.mainContainer.alpha = 0;
            this.mainContainer.scale.set(0.7);
            this.background.alpha = 0;
            this.totemContainer.visible = false;
            this.game.add.tween(this.background)
                .to({ alpha: 1 }, 500, Phaser.Easing.Circular.Out, true, 0);
            this.game.add.tween(this.mainContainer)
                .to({ alpha: 1 }, 400, Phaser.Easing.Exponential.Out, true, 400);
            this.game.add.tween(this.mainContainer.scale)
                .to({ x: 1, y: 1 }, 400, Phaser.Easing.Back.Out, true, 400)
                .onComplete.add(this.startTweens, this);
            this.board.show(
                function () {
                    return _this.burnFire();
                },
                [this.buttonNext, this.buttonHome, this.buttonRestart, this.buttonNextShining]
            );
        };
        ResultsWindow.prototype.startTweens = function () {
            this.totemContainer.visible = true;
            this.game.add.tween(this.totemContainer)
                .to({ y: -374 }, 500, Phaser.Easing.Cubic.Out, true, 0);
            this.monkeyTop.scale.y = 1.01;
            this.game.add.tween(this.monkeyTop.scale)
                .to({ y: 1 }, 200, Phaser.Easing.Linear.None, true, 500);
            this.leafsAnimation.startTweens();
            this.feathersAnimation.startTweens();
        };
        ResultsWindow.prototype.burnFire = function () {
            this.fireLeft.visible = true;
            this.fireRight.visible = true;
            this.fireLeftStartAnimation.restart();
            this.fireRightStartAnimation.restart();
            this.torchStartSound.play();
            this.torchLoopSound.play();
        };
        ResultsWindow.prototype.clearTweens = function () {
            this.game.tweens.removeFrom(this.background);
            this.game.tweens.removeFrom(this.mainContainer);
            this.game.tweens.removeFrom(this.mainContainer.scale);
            this.game.tweens.removeFrom(this.totemContainer);
            this.game.tweens.removeFrom(this.monkeyTop.scale);
            this.fireLeft.visible = false;
            this.fireRight.visible = false;
            this.fireLeftStartAnimation.stop(true);
            this.fireRightStartAnimation.stop(true);
            this.totemContainer.y = -180;
        };
        ResultsWindow.prototype.hide = function () {
            src.SoundController.instance.restoreMusicVolume();
            this.torchStartSound.stop();
            this.torchLoopSound.stop();
            this.clearTweens();
            this.board.hide();
            _super.prototype.hide.call(this);
        };
        ResultsWindow.prototype.homeClicked = function () {
            var _this = this;
            this.lockUpButtons(this.buttonHome, this.buttonNext, this.buttonRestart);
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.transitionTo('MainMenu', function () { return _this.hide(); });
            src.App.instance.showAd(50);
        };
        ResultsWindow.prototype.nextClicked = function () {
            var _this = this;
            this.lockUpButtons(this.buttonHome, this.buttonNext, this.buttonRestart);
            this.game.sound.play('click', 0.9);
            if (src.Settings.CURRENT_LEVEL < src.Settings.TOTAL_LEVELS) {
                src.LevelManager.instance.loadLevel(src.Settings.CURRENT_LEVEL + 1);
                src.WindowManager.instance.transitionTo('Level', function () { return _this.hide(); });
            }
            else {
                src.WindowManager.instance.transitionTo('MainMenu', function () { return _this.hide(); });
            }
            src.App.instance.showAd(50);
        };
        ResultsWindow.prototype.restartClicked = function () {
            var _this = this;
            this.lockUpButtons(this.buttonHome, this.buttonNext, this.buttonRestart);
            this.game.sound.play('click', 0.9);
            src.WindowManager.instance.transitionTo("Level", function () { return _this.hide(); });
            window.famobi_analytics.trackEvent(window.famobi_analytics.EVENT_LEVELRESTART, {
                levelName: '' + src.Settings.CURRENT_LEVEL
            });
            src.App.instance.showAd(50);
        };
        return ResultsWindow;
    }(src.BaseWindow));
    src.ResultsWindow = ResultsWindow;
})(src || (src = {}));
//# sourceMappingURL=out.js.map
