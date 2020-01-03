using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(CloudsRayMarchingRenderer), PostProcessEvent.AfterStack, "Custom/CloudsRayMarchingImageFX")]
public sealed class ImageEffectCloudsRayMarching : PostProcessEffectSettings
{
    [Tooltip("white Noise texture for quick noise lookups."), DisplayName("Noise Texture")]
    public TextureParameter noiseTex = new TextureParameter { value = null }; //TODO: throwing errors if no texture assigned

    [Range(0f, 1f), Tooltip("Effect intensity.")]
    public FloatParameter blend = new FloatParameter { value = 0.5f };

    [Tooltip("Dimension of noise texture")]
    public FloatParameter noiseTexDimension = new FloatParameter { value = 512f };
}

public sealed class CloudsRayMarchingRenderer : PostProcessEffectRenderer<ImageEffectCloudsRayMarching>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Custom/CloudsRayMarchingImageFX"));
        sheet.properties.SetFloat("_Blend", settings.blend);
        sheet.properties.SetFloat("_NoiseTexDimension", settings.noiseTexDimension);
        sheet.properties.SetTexture("_NoiseTex", settings.noiseTex);
        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}