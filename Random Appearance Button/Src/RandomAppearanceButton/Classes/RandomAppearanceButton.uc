/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    Random Appearance Button CORE CLASS

    This mod provides randomization buttons for soldier appearance customization
    overlaying the UICustomization_Menu (basic soldier attributes like face and hairstyle).

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

class RandomAppearanceButton extends UIScreenListener
    dependson(RandomAppearanceButton_Utilities)
    config(RandomAppearanceButton);

/*
    Based on XGCharacterGenerator's standard procedure for making a new (normal-looking) soldier.
    Declarations ripped right from there (including the comment)
*/
var config float    RABConf_HatChance;
var config float    RABConf_UpperFacePropChance;
var config float    RABConf_LowerFacePropChance;
var config float    RABConf_BeardChance;
var config float    RABConf_ArmorPatternChance;
var config float    RABConf_WeaponPatternChance;
var config float    RABConf_TattoosChance;
var config float    RABConf_ScarsChance;
var config float    RABConf_FacePaintChance;

var config bool     RABConf_ForceDefaultColors;
var config int      RABConf_DefaultArmorColors;
var config int      RABConf_DefaultWeaponColors;
var config int      RABConf_DefaultHairColors;
var config int      RABConf_DefaultEyeColors;

// Added for Anarchy's children and similar DLC
var config int      RABConf_HairRangeMaleLimit;
var config int      RABConf_HairRangeFemaleLimit;
var config int      RABConf_HelmRangeLimit;
var config int      RABConf_ArmsRangeLimit;
var config int      RABConf_LegsRangeLimit;
var config int      RABConf_TorsoRangeLimit;
var config int      RABConf_UpperFacePropLimit;
var config int      RABConf_LowerFacePropLimit;
var config float    RABConf_TotallyRandom_AnarchysChildrenArmsChance;

enum EForceDefaultColorFlags {
    eForceDefaultColorFlag_NotForced,
    eForceDefaultColorFlag_ArmorColors,
    eForceDefaultColorFlag_WeaponColors,
    eForceDefaultColorFlag_HairColors,
    eForceDefaultColorFlag_EyeColors
};

const DLC_1_STR = "DLC_1";
var bool                isDLC_1_Installed;

var UICustomize_Menu    CustomizeMenuScreen;

var UIBGBox             ButtonsBGBox;
var UIText              ButtonsTitle;
var UIText              ColorTitle;
var UIText              PersonTitle;
var UIText              TotalTitle;

var UIButton            RandomAppearanceButton;
var UIButton            TotallyRandomButton;
var UIButton            RandomHelmetButton;
var UIButton            ClearHelmetButton;
var UIButton            RandomHairButton;
var UIButton            ClearHairButton;
var UIButton            RandomHairColorButton;
var UIButton            RandomEyeColorButton;
var UIButton            RandomUpperButton;
var UIButton            ClearUpperButton;
var UIButton            RandomLowerButton;
var UIButton            ClearLowerButton;
var UIButton            RandomFacePaintButton;
var UIButton            ClearFacePaintButton;
var UIButton            RandomScarsButton;
var UIButton            ClearScarsButton;
var UIButton            RandomFacialHairButton;
var UIButton            ClearFacialHairButton;
var UIButton            RandomAttitudeButton;
var UIButton            ByTheBookButton;
var UIButton            RandomFaceButton;
var UIButton            RandomRaceButton;
var UIButton            RandomSkinColorButton;

/*
    Starting with the coords from the random nickname button mod.
*/

const BUTTON_LABEL_FONTSIZE     = 22;   // smaller text
const BUTTON_HEIGHT             = 30;   // guesstimate, also smaller

const ROW_OUTLINING             = 35;
const TOP_OFFSET                = 100;
const RIGHT_OFFSET              = 20;

// I needed a local decl of this in rand.nickname in order to make
// a generalized create button func, so...here it is again.
delegate OnClickedDelegate(UIButton Button);

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

                            UIScreenListener Callbacks

    Right now we can only count on OnInit.

    The focus events don't fire for color pickers, limiting their use.
    (I use them anyway in good faith they'll one day work as I wish.)

    OnRemove isn't required as I have no cleanup; as far as I've
    gathered, Unreal's garbage collection vs. mods is sufficient.

    NOTE. I could "sidechannel" this by setting up one or more other
    UIScreenListeners perhaps: ones that wake up when color pickers are
    noticed IF they count as screens. I'm not sure how else to do it;
    other than, you know, hope Firaxis eventually makes color pickers
    fire focus events.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

event OnInit(UIScreen Screen)
{
    CustomizeMenuScreen = UICustomize_Menu(Screen);
    if (CustomizeMenuScreen == none)
        return;

    RunDLCCheck();

    InitRandomAppearanceButtonUI();
}

simulated function OnReceiveFocus(UIScreen Screen)
{
    `log("RandomAppearanceButton.OnReceiveFocus");

    ShowUI();
}

simulated function OnLoseFocus(UIScreen Screen)
{
    `log("RandomAppearanceButton.OnLoseFocus");

    HideUI();
}

event onRemoved(UIScreen Screen)
{
    ButtonsBGBox.Destroy();
    ButtonsTitle.Destroy();
    ColorTitle.Destroy();
    PersonTitle.Destroy();
    TotalTitle.Destroy();
    ClearHelmetButton.Destroy();
    RandomHelmetButton.Destroy();
    RandomHairButton.Destroy();
    ClearHairButton.Destroy();
    ClearFacePaintButton.Destroy();
    RandomFacePaintButton.Destroy();
    ClearScarsButton.Destroy();
    RandomScarsButton.Destroy();
    ClearFacialHairButton.Destroy();
    RandomFacialHairButton.Destroy();
    RandomHairColorButton.Destroy();
    RandomEyeColorButton.Destroy();
    ByTheBookButton.Destroy();
    RandomAttitudeButton.Destroy();
    RandomFaceButton.Destroy();
    RandomRaceButton.Destroy();
    RandomSkinColorButton.Destroy();
    ClearUpperButton.Destroy();
    RandomUpperButton.Destroy();
    ClearLowerButton.Destroy();
    RandomLowerButton.Destroy();
    RandomAppearanceButton.Destroy();
    TotallyRandomButton.Destroy();
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

Random Appearance Button UI code

    Handles UI stuff particular to this mod.

    NOTE.   There are times that I consider strongly moving this (and
            the randomize code) out to support classes and turn this
            class into a pure go-between. I may end up doing that if
            I either find it facilitates compatibility with other mods
            OR if I have a sudden glut of time.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated function InitRandomAppearanceButtonUI()
{
    /*
        Creates the lower panel of buttons.
    */

    // Create background box for all buttons including Undo
    ButtonsBGBox = CustomizeMenuScreen.Spawn(class'UIBGBox', CustomizeMenuScreen);
    ButtonsBGBox.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
    ButtonsBGBox.InitBG('ButtonsBGBox');

    ButtonsBGBox.SetWidth(325);
    ButtonsBGBox.SetHeight(585);
    ButtonsBGBox.AnchorTopRight();
	ButtonsBGBox.OriginTopRight();
    ButtonsBGBox.SetPosition(-10, 50);

    // Create title for the panel
    ButtonsTitle = CustomizeMenuScreen.Spawn(class'UIText', CustomizeMenuScreen);
    ButtonsTitle.InitText('ButtonsTitle');
    ButtonsTitle.SetHTMLText(class'UIUtilities_Text'.static.StyleText("Head Randomizer", eUITextStyle_Tooltip_Title));
    ButtonsTitle.AnchorTopRight();
    ButtonsTitle.SetPosition(-240 - RIGHT_OFFSET, 65);

    RandomHelmetButton                  = CreateButton('RandomHelmetButton',        "Helm",					OnRandomHelmetButtonClicked,			class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET);
    ClearHelmetButton                   = CreateButton('ClearHelmetButton',         "Remove",				OnClearHelmetButtonClicked,             class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET);

    RandomUpperButton                   = CreateButton('RandomUpperButton',         "Upper",				OnRandomUpperButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 1*ROW_OUTLINING);
    ClearUpperButton                    = CreateButton('ClearUpperButton',          "Remove",				OnClearUpperButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 1*ROW_OUTLINING);

    RandomLowerButton                   = CreateButton('RandomLowerButton',         "Lower",				OnRandomLowerButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 2*ROW_OUTLINING);
    ClearLowerButton                    = CreateButton('ClearLowerButton',          "Remove",				OnClearLowerButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 2*ROW_OUTLINING);

    RandomHairButton                    = CreateButton('RandomHairButton',          "Hair",					OnRandomHairButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 3*ROW_OUTLINING);
    ClearHairButton                     = CreateButton('ClearHairButton',           "Remove",				OnClearHairButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 3*ROW_OUTLINING);

    RandomFacePaintButton               = CreateButton('RandomFacePaintButton',     "Paint",				OnRandomFacePaintButtonClicked,		    class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 4*ROW_OUTLINING);
    ClearFacePaintButton                = CreateButton('ClearFacePaintButton',      "Remove",				OnClearFacePaintButtonClicked,			class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 4*ROW_OUTLINING);

    RandomScarsButton                   = CreateButton('RandomScarsButton',         "Scars",				OnRandomScarsButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 5*ROW_OUTLINING);
    ClearScarsButton                    = CreateButton('ClearScarsButton',          "Remove",				OnClearScarsButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 5*ROW_OUTLINING);

    RandomFacialHairButton              = CreateButton('RandomFacialHairButton',    "Beard",				OnRandomFacialHairButtonClicked,		class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 6*ROW_OUTLINING);
    ClearFacialHairButton               = CreateButton('ClearFacialHairButton',     "Remove",				OnClearFacialHairButtonClicked,		    class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 6*ROW_OUTLINING);

    // Create Color Randomizer title
    ColorTitle = CustomizeMenuScreen.Spawn(class'UIText', CustomizeMenuScreen);
    ColorTitle.InitText('ColorTitle');
    ColorTitle.SetHTMLText(class'UIUtilities_Text'.static.StyleText("Color Randomizer", eUITextStyle_Tooltip_Title));
    ColorTitle.AnchorTopRight();
    ColorTitle.SetPosition(-240 - RIGHT_OFFSET, TOP_OFFSET + 7*ROW_OUTLINING);

    RandomHairColorButton               = CreateButton('RandomHairColorButton',     "Hair Color",			OnRandomHairColorButtonClicked,			class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 8*ROW_OUTLINING);
    RandomEyeColorButton                = CreateButton('RandomEyeColorButton',      "Eyes Color",			OnRandomEyeColorButtonClicked,			class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 8*ROW_OUTLINING);

    RandomSkinColorButton               = CreateButton('RandomSkinColorButton',     "Skin Color",			OnRandomSkinColorButtonClicked,			class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -225 - RIGHT_OFFSET, TOP_OFFSET + 9*ROW_OUTLINING);

    // Create Person Randomizer title
    PersonTitle = CustomizeMenuScreen.Spawn(class'UIText', CustomizeMenuScreen);
    PersonTitle.InitText('PersonTitle');
    PersonTitle.SetHTMLText(class'UIUtilities_Text'.static.StyleText("Person Randomizer", eUITextStyle_Tooltip_Title));
    PersonTitle.AnchorTopRight();
    PersonTitle.SetPosition(-240 - RIGHT_OFFSET, TOP_OFFSET + 10*ROW_OUTLINING);

    RandomFaceButton                    = CreateButton('RandomFaceButton',          "Face",					OnRandomFaceButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 11*ROW_OUTLINING);
    RandomRaceButton                    = CreateButton('RandomRaceButton',          "Race",					OnRandomRaceButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 11*ROW_OUTLINING);

    RandomAttitudeButton                = CreateButton('RandomAttitudeButton',      "Attitude",				OnRandomAttitudeButtonClicked,			class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 12*ROW_OUTLINING);
    ByTheBookButton                     = CreateButton('ByTheBookButton',           "Remove",			    OnByTheBookButtonClicked,				class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 12*ROW_OUTLINING);

    // Create Total Randomizer title
    TotalTitle = CustomizeMenuScreen.Spawn(class'UIText', CustomizeMenuScreen);
    TotalTitle.InitText('TotalTitle');
    TotalTitle.SetHTMLText(class'UIUtilities_Text'.static.StyleText("Total Randomizer", eUITextStyle_Tooltip_Title));
    TotalTitle.AnchorTopRight();
    TotalTitle.SetPosition(-240 - RIGHT_OFFSET, TOP_OFFSET + 13*ROW_OUTLINING);

    RandomAppearanceButton              = CreateButton('RandomAppearanceButton',    "Random",				GenerateNormalLookingRandomAppearance,  class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -303 - RIGHT_OFFSET, TOP_OFFSET + 14*ROW_OUTLINING);
    TotallyRandomButton                 = CreateButton('TotallyRandomButton',       "Full Random",          GenerateTotallyRandomAppearance,        class'UIUtilities'.const.ANCHOR_TOP_RIGHT, -150 - RIGHT_OFFSET, TOP_OFFSET + 14*ROW_OUTLINING);

}

// Generic methods for button handlers
simulated function OnRandomizeTrait(EUICustomizeCategory eCategory)
{
    RandomizeTrait(eCategory, true);
    UpdateScreenData();
    ResetCamera();
}

simulated function ClearTrait(EUICustomizeCategory eCategory)
{
    SetTrait(eCategory, 0);
    UpdateScreenData();
    ResetCamera();
}

// Simplified button handlers
simulated function OnRandomHelmetButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_Helmet);
}

simulated function OnClearHelmetButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_Helmet);
}

simulated function OnRandomHairButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_Hairstyle);
}

simulated function OnClearHairButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_Hairstyle);
}

simulated function OnRandomHairColorButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_HairColor);
}

simulated function OnRandomEyeColorButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_EyeColor);
}

simulated function OnRandomAttitudeButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_Personality);
}

simulated function OnByTheBookButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_Personality);
}

simulated function OnRandomFaceButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_Face);
}

simulated function OnRandomRaceButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_Race);
}

simulated function OnRandomSkinColorButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_Skin);
}

simulated function OnRandomUpperButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_FaceDecorationUpper);
}

simulated function OnClearUpperButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_FaceDecorationUpper);
}

simulated function OnRandomLowerButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_FaceDecorationLower);
}

simulated function OnClearLowerButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_FaceDecorationLower);
}

simulated function OnRandomFacePaintButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_FacePaint);
}

simulated function OnClearFacePaintButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_FacePaint);
}

simulated function OnRandomScarsButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_Scars);
}

simulated function OnClearScarsButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_Scars);
}

simulated function OnRandomFacialHairButtonClicked(UIButton Button)
{
    OnRandomizeTrait(eUICustomizeCat_FacialHair);
}

simulated function OnClearFacialHairButtonClicked(UIButton Button)
{
    ClearTrait(eUICustomizeCat_FacialHair);
}

simulated function HideUI()
{
    /*
        Hides the mod's UI when losing focus.
    */

    ButtonsBGBox.Hide();
    ButtonsTitle.Hide();
    ColorTitle.Hide();
    PersonTitle.Hide();
    TotalTitle.Hide();
    ClearHelmetButton.Hide();
    RandomHelmetButton.Hide();
    RandomHairButton.Hide();
    ClearHairButton.Hide();
    ClearFacePaintButton.Hide();
    RandomFacePaintButton.Hide();
    ClearScarsButton.Hide();
    RandomScarsButton.Hide();
    ClearFacialHairButton.Hide();
    RandomFacialHairButton.Hide();
    RandomHairColorButton.Hide();
    RandomEyeColorButton.Hide();
    ByTheBookButton.Hide();
    RandomAttitudeButton.Hide();
    RandomFaceButton.Hide();
    RandomRaceButton.Hide();
    RandomSkinColorButton.Hide();
    ClearUpperButton.Hide();
    RandomUpperButton.Hide();
    ClearLowerButton.Hide();
    RandomLowerButton.Hide();
    RandomAppearanceButton.Hide();
    TotallyRandomButton.Hide();

}

simulated function ShowUI()
{
    /*
        Shows the mod's UI when gaining focus.
    */

    ButtonsBGBox.Show();
    ButtonsTitle.Show();
    ColorTitle.Show();
    PersonTitle.Show();
    TotalTitle.Show();
    ClearHelmetButton.Show();
    RandomHelmetButton.Show();
    RandomHairButton.Show();
    ClearHairButton.Show();
    ClearFacePaintButton.Show();
    RandomFacePaintButton.Show();
    ClearScarsButton.Show();
    RandomScarsButton.Show();
    ClearFacialHairButton.Show();
    RandomFacialHairButton.Show();
    RandomHairColorButton.Show();
    RandomEyeColorButton.Show();
    ByTheBookButton.Show();
    RandomAttitudeButton.Show();
    RandomFaceButton.Show();
    RandomRaceButton.Show();
    RandomSkinColorButton.Show();
    ClearUpperButton.Show();
    RandomUpperButton.Show();
    ClearLowerButton.Show();
    RandomLowerButton.Show();
    RandomAppearanceButton.Show();
    TotallyRandomButton.Show();

}



/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    Generic UI code: spawn buttons, backgrounds, etc. particular to my
    Customization screen UI mods.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated function UIButton CreateButton(name ButtonName, string ButtonLabel,
                                        delegate<OnClickedDelegate> OnClickCallThis,
                                        int AnchorPos, int XOffset, int YOffset)
{
    local UIButton  NewButton;

    NewButton = CustomizeMenuScreen.Spawn(class'UIButton', CustomizeMenuScreen);
    NewButton.InitButton(ButtonName, class'UIUtilities_Text'.static.GetSizedText(ButtonLabel, BUTTON_LABEL_FONTSIZE), OnClickCallThis);
    NewButton.SetAnchor(AnchorPos);
    NewButton.SetPosition(XOffset, YOffset);
    NewButton.SetSize(NewButton.Width, BUTTON_HEIGHT);

    return NewButton;
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

    Random Appearance code

    Randomized trait setting code all lives here. Could be broken out
    into a support class, given time.

* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

simulated function GenerateTotallyRandomAppearance(UIButton Button)
{
    /*
        (Unused param is a UE3 thing: required for UIButton callback.)
    */

    `log("");
    `log("* * * * * * * * * * * * * * * * * * * * * * * * *");
    `log("");
    `log("GENERATING TOTALLY RANDOM APPEARANCE");
    `log("");
    `log("* * * * * * * * * * * * * * * * * * * * * * * * *");
    `log("");

    /*
        Order of trait application matters: gender first (which we don't roll for) then
        race (which seems to matter sometimes).
    */

    // Core customization menu
    RandomizeTrait(eUICustomizeCat_Race,                true);
    RandomizeTrait(eUICustomizeCat_Face,                true);
    RandomizeTrait(eUICustomizeCat_Hairstyle,           true);
    RandomizeTrait(eUICustomizeCat_FacialHair,          true);
    RandomizeTrait(eUICustomizeCat_HairColor,           true);
    RandomizeTrait(eUICustomizeCat_EyeColor,            true);
    RandomizeTrait(eUICustomizeCat_Personality,         true);
    RandomizeTrait(eUICustomizeCat_Skin,                true);
    RandomizeTrait(eUICustomizeCat_PrimaryArmorColor,   true);
    RandomizeTrait(eUICustomizeCat_SecondaryArmorColor, true);
    RandomizeTrait(eUICustomizeCat_WeaponColor,         true);

    // customize props menu
    RandomizeTrait(eUICustomizeCat_FaceDecorationUpper, true);
    RandomizeTrait(eUICustomizeCat_FaceDecorationLower, true);
    RandomizeTrait(eUICustomizeCat_Helmet,              true);
    RandomizeTrait(eUICustomizeCat_Torso,               true);
    RandomizeTrait(eUICustomizeCat_Legs,                true);
    RandomizeTrait(eUICustomizeCat_ArmorPatterns,       true);
    RandomizeTrait(eUICustomizeCat_WeaponPatterns,      true);
    RandomizeTrait(eUICustomizeCat_LeftArmTattoos,      true);
    RandomizeTrait(eUICustomizeCat_RightArmTattoos,     true);
    RandomizeTrait(eUICustomizeCat_TattooColor,         true);
    RandomizeTrait(eUICustomizeCat_Scars,               true);
    RandomizeTrait(eUICustomizeCat_FacePaint,           true);

    `log("DOING ARMS.");
    `log("Checking for DLC1.");
    // deal with anarchy's children dlc
    if (isDLC_1_Installed)
    {
        `log("DLC1 installed.");
        HandleDLC1();
    } else {
        `log("No DLC, rolling arms as normal.");
        RandomizeTrait(eUICustomizeCat_Arms,            true);
    }
    `log("DONE WITH ARMS.");

    UpdateScreenData();
    ResetCamera();
}

simulated function bool HandleDLC1()
{
    local bool bUsingDLC1Arms;

    /*
        Simplified logic for DLC arms handling since all locks have been removed.
        We now only need to check for DLC torso compatibility and use % chance configuration.
    */

    if (class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Torso(CustomizeMenuScreen)) {
        // vanilla arms not allowed with DLC1 torso, force roll on DLC1 arms.
        bUsingDLC1Arms = true;
        RandomizeDLC1ArmSlots();
    } else {
        bUsingDLC1Arms = false;
        RandomizeTrait(eUICustomizeCat_Arms, true);

        if (RandomizeOrNotBasedOnRoll(RABConf_TotallyRandom_AnarchysChildrenArmsChance)) {
            /*
                Use DLC arm elements based on config chance to provide variety
                between vanilla and DLC arms.
            */
            bUsingDLC1Arms = true;
            RandomizeDLC1ArmSlots();
        }
    }

    return bUsingDLC1Arms;
}

simulated function RandomizeDLC1ArmSlots()
{
    RandomizeTrait(eUICustomizeCat_LeftArmDeco,     true);
    RandomizeTrait(eUICustomizeCat_RightArmDeco,    true);
    RandomizeTrait(eUICustomizeCat_LeftArm,         true);
    RandomizeTrait(eUICustomizeCat_RightArm,        true);
}

simulated function GenerateNormalLookingRandomAppearance(UIButton Button)
{
    /*
        (Unused param is a UE3 thing: required for UIButton callback.)
    */

    `log("");
    `log("* * * * * * * * * * * * * * * * * * * * * * * * *");
    `log("");
    `log("GENERATING NORMAL LOOKING APPEARANCE");
    `log("");
    `log("* * * * * * * * * * * * * * * * * * * * * * * * *");
    `log("");

    /*
        The order here is important:
        * Setting Race can override the face, so we set that first. (Gender trumps Race in this regard; trumps everything really.)
        * Where DLC_1 is concerned, the DLC_1 torsos forbid the vanilla arms, so set THAT first, just incase.
    */

    // --> If we DID randomize on gender, that would go here, as it goes first. <--
    RandomizeTrait(eUICustomizeCat_Race);
    RandomizeTrait(eUICustomizeCat_Skin);

    RandomizeTrait(eUICustomizeCat_Face);
    RandomizeTrait(eUICustomizeCat_Hairstyle);
    RandomizeTrait(eUICustomizeCat_Personality);

    RandomizeTrait(eUICustomizeCat_Torso);
    if ( class'RandomAppearanceButton_Utilities'.static.SoldierHasDLC1Torso(CustomizeMenuScreen) ) {
        // No choice, can't use vanilla arms with DLC_1 arms.
        RandomizeDLC1ArmSlots();
    } else {
        // This is a "normal looking" soldier, so, we want vanilla arms.
        RandomizeTrait(eUICustomizeCat_Arms);
    }

    RandomizeTrait(eUICustomizeCat_Legs);

    /*
        Conditionally randomize these (configurable in XComRandomAppearanceButton.ini).

        Optionals per the game's default soldier generator: facial hair and decorations, hat.
        Optionals per me: armor and weapon patterns, tattoos, scars, face paint.

        Basically need to clear any/all extended stuff so the result here doesn't look like it's fixed
        and weird.

        If you click the button and get a hat, that hat will persist through further clicks on the button...which
        feels weird; so I clear the hat (and other props) then regen based on the chance to get one again.
    */
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacialHair,             RABConf_BeardChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationUpper,    RABConf_UpperFacePropChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FaceDecorationLower,    RABConf_LowerFacePropChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Helmet,                 RABConf_HatChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_ArmorPatterns,          RABConf_ArmorPatternChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_WeaponPatterns,         RABConf_WeaponPatternChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_Scars,                  RABConf_ScarsChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_FacePaint,              RABConf_FacePaintChance);

    /*
        I handle the tattoos as one field; could handle them individually as I do everything else, but this made
        more sense to me.

        Set the color (if there are no tattoos, no worries, it won't show up).
    */
    RandomizeTrait(eUICustomizeCat_TattooColor);

    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_LeftArmTattoos,         RABConf_TattoosChance);
    ResetAndConditionallyRandomizeTrait(eUICustomizeCat_RightArmTattoos,        RABConf_TattoosChance);

    /*
        Colors!
    */
    if (RABConf_ForceDefaultColors)
    {
        RandomizeTrait(eUICustomizeCat_HairColor,               false, EForceDefaultColorFlags.eForceDefaultColorFlag_HairColors);
        RandomizeTrait(eUICustomizeCat_PrimaryArmorColor,       false, EForceDefaultColorFlags.eForceDefaultColorFlag_ArmorColors);
        RandomizeTrait(eUICustomizeCat_SecondaryArmorColor,     false, EForceDefaultColorFlags.eForceDefaultColorFlag_ArmorColors);
        RandomizeTrait(eUICustomizeCat_WeaponColor,             false, EForceDefaultColorFlags.eForceDefaultColorFlag_WeaponColors);
        RandomizeTrait(eUICustomizeCat_EyeColor,                false, EForceDefaultColorFlags.eForceDefaultColorFlag_EyeColors);
    }
    else
    {
        RandomizeTrait(eUICustomizeCat_HairColor);
        RandomizeTrait(eUICustomizeCat_PrimaryArmorColor);
        RandomizeTrait(eUICustomizeCat_SecondaryArmorColor);
        RandomizeTrait(eUICustomizeCat_WeaponColor);
        RandomizeTrait(eUICustomizeCat_EyeColor);
    }

    UpdateScreenData();
    ResetCamera();


}



simulated function ResetAndRandomize(EUICustomizeCategory eCategory)
{
    SetTrait(eCategory, 0);
    RandomizeTrait(eCategory);
}

simulated function ResetAndConditionallyRandomizeTrait(EUICustomizeCategory eCategory, float fChanceToRandomize)
{
    /*
        Reset the trait to 0 then, if we're supposed to randomize it, do so.
    */

    SetTrait(eCategory, 0);
    if (RandomizeOrNotBasedOnRoll(fChanceToRandomize)) {
        RandomizeTrait(eCategory);
    }
}

simulated function RandomizeTrait(EUICustomizeCategory eCategory, optional bool bTotallyRandom = false, optional EForceDefaultColorFlags eForceDefaultColor = eForceDefaultColorFlag_NotForced)
{
    /*
        The linchpin of the whole mod here, RandomizeTrait rolls a random trait out
        of all the options for a given Customize Category, handles config around
        default colors, then calls OnCategoryValueChange. Basically my mod acts as
        if the player is clicking the UI, instead of changing the soldier directly,
        allowing all the UI built-in safety checks to benefit my mod AND reducing
        the number of classes I need to hook into by a pretty big number.
    */

    local int           maxOptions;
    local int           iCategory;
    local ECategoryType eCatType;
    local int           iDirection;

    iCategory = eCategory; // annoying caveat to UE3; casting inline doesn't work below
    eCatType = class'RandomAppearanceButton_Utilities'.static.GetCategoryType(iCategory);
    iDirection = class'RandomAppearanceButton_Utilities'.static.PropDirection(eCatType);

    switch (iDirection) {
        case 0:
            maxOptions = GetMaxRangeForProp(eCategory, bTotallyRandom);
            break;
        case -1:
            maxOptions = GetMaxRangeForColors(eCategory, bTotallyRandom, eForceDefaultColor);
            break;
    }

    /*
        Here's the meat of the function: we pass a random value (within the determined range)
        to the customize manager via OnCategoryValueChange, which is actually a callback
        usually triggered by UI interaction, I think. (That's why I need to manually call
        UpdateCamera immediately after (with no args) otherwise the camera gets weird.
    */

    `log("RAB: maxOptions = " $ maxOptions);

    SetTrait(eCategory, `SYNC_RAND(maxOptions));
}



simulated static function ForceSetTrait(UICustomize_Menu Screen, EUICustomizeCategory eCategory, int iSetting)
{
    local ECategoryType     eCatType;
    local int               iDirection;
    local int               iCategory;

    iCategory = eCategory; // annoying caveat of UE3; inline casting won't work below
    eCatType = class'RandomAppearanceButton_Utilities'.static.GetCategoryType(iCategory);
    iDirection = class'RandomAppearanceButton_Utilities'.static.PropDirection(eCatType);

    /*
        OnCategoryValueChange, which is actually a callback usually triggered
        by UI interaction. Basically the game responds to my mod the same way
        it responds to the user clicking on a given setting within a picker.
    */
    Screen.CustomizeManager.OnCategoryValueChange(eCategory, iDirection, iSetting);
    Screen.CustomizeManager.UpdateCamera();
}

simulated function SetTrait(EUICustomizeCategory eCategory, int iTraitIndex)
{
    ForceSetTrait(CustomizeMenuScreen, eCategory, iTraitIndex);
}

simulated static function int GetTrait(UICustomize_Menu Screen, EUICustomizeCategory eCategory)
{
    /*
        Return the (relative) index for the given trait.
    */

    return Screen.CustomizeManager.GetCategoryIndex(eCategory);
}

private function ResetCamera()
{
    /*
        Calling this with no args helps correct the camera, which
        becomes weird (locked, zoomed) otherwise.
    */

    class'RandomAppearanceButton_Utilities'.static.ResetCamera(CustomizeMenuScreen);
}

private function UpdateScreenData()
{
    /*
        Calling this is necessary to cement certain changes, like
        changes to soldier gender.

        This is a local wrapper for a long-named static function.
    */

    class'RandomAppearanceButton_Utilities'.static.UpdateScreenData(CustomizeMenuScreen);
}

simulated function int GetMaxRangeForProp(EUICustomizeCategory eCategory, bool bTotallyRandom)
{
    /*
        The user can set a ceiling for prop selection in the config.
        It's not complicated as, right now, most "reasonable" options are
        lower in the list and the crazy ones are higher.
    */

    local array<string> options;
    local int           maxOptions;

    local int           maxRangeFromConfig;
    local int           gender;

    gender = GetGender();

    options = CustomizeMenuScreen.CustomizeManager.GetCategoryList(eCategory);
    maxOptions = options.Length;

    /*
        Check config
    */

    switch (eCategory)
    {
        case eUICustomizeCat_Hairstyle:
            // conditional on gender; want to avoid the "no gender" enum which has no props, so we're explicit.
            if (gender == eGender_Female)
                maxRangeFromConfig = RABConf_HairRangeFemaleLimit;
            else
                maxRangeFromConfig = RABConf_HairRangeMaleLimit;
            break;

        case eUICustomizeCat_Helmet:
            maxRangeFromConfig = RABConf_HelmRangeLimit;
            break;

        case eUICustomizeCat_Arms:
            maxRangeFromConfig = RABConf_ArmsRangeLimit;
            break;

        case eUICustomizeCat_Legs:
            maxRangeFromConfig = RABConf_LegsRangeLimit;
            break;

        case eUICustomizeCat_Torso:
            maxRangeFromConfig = RABConf_TorsoRangeLimit;
            break;

        case eUICustomizeCat_FaceDecorationUpper:
            maxRangeFromConfig = RABConf_UpperFacePropLimit;
            break;

        case eUICustomizeCat_FaceDecorationLower:
            maxRangeFromConfig = RABConf_LowerFacePropLimit;
            break;

        default:
            maxRangeFromConfig = -1;
            break;
    }

    /*
        if (maxRangeFromConfig > maxOptions)
            Then there's an error in the config, so we ignore it.
    */

    if (maxRangeFromConfig > -1 && maxOptions > maxRangeFromConfig && !bTotallyRandom)
        maxOptions = maxRangeFromConfig;

    return maxOptions;
}

simulated function int GetMaxRangeForColors(EUICustomizeCategory eCategory, bool bTotallyRandom, EForceDefaultColorFlags eForceDefaultColor)
{
    local array<string> options;
    local int           maxOptions;

    options = CustomizeMenuScreen.CustomizeManager.GetColorList(eCategory);
    maxOptions = options.Length;

    /*
        The config allows the user to choose whether "reasonable looking" soldiers
        are generated with or without restrictions on colors. Currently there's only
        one setting (all or nothing) but it's probably a good idea (and not much work)
        to make it such that the user can set it for each type of color individually.
    */

    if (!bTotallyRandom)
    {
        switch (eForceDefaultColor) {

            case eForceDefaultColorFlag_ArmorColors:
                //`log(" * USING DEFAULT ARMOR COLORS.");
                maxOptions = RABConf_DefaultArmorColors;
                break;

            case eForceDefaultColorFlag_WeaponColors:
                //`log(" * USING DEFAULT WEAPON COLORS.");
                maxOptions = RABConf_DefaultWeaponColors;
                break;

            case eForceDefaultColorFlag_EyeColors:
                //`log(" * USING DEFAULT EYE COLORS.");
                maxOptions = RABConf_DefaultEyeColors;
                break;

            case eForceDefaultColorFlag_HairColors:
                `log(" * USING DEFAULT HAIR COLORS.");
                maxOptions = RABConf_DefaultHairColors;
                break;

            case eForceDefaultColorFlag_NotForced:
            default:
                // Nothing to do here, maxOptions already correct per its init
                break;
        }

    }

    return maxOptions;
}

simulated function int GetGender()
{
    local XComGameState_Unit unit;

     unit = CustomizeMenuScreen.Movie.Pres.GetCustomizationUnit();

     return unit.kAppearance.iGender;
}

simulated function bool RandomizeOrNotBasedOnRoll(float Chance)
{
    if (`SYNC_FRAND() < Chance)
        return true;
    else
        return false;
}


simulated function RunDLCCheck()
{
    /*
        As more DLC comes down the pipe that affects this, I can add
        it to this check loop in the same way.
    */

    local array<string> installedDlcNames;
    local int i;

    installedDlcNames = class'Helpers'.static.GetInstalledDLCNames();

    for (i=0; i<installedDlcNames.Length; i++)
    {
        `log(" -->" @ i @ installedDlcNames[i]);
        if (installedDLCNames[i] == DLC_1_STR)
            isDLC_1_Installed = true;
    }
}

defaultproperties
{
    ScreenClass = class'UICustomize_Menu';
}

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */