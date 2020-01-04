using System;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;

[Serializable]
[PostProcess(typeof(CloudsRayMarchingRenderer), PostProcessEvent.AfterStack, "Custom/CloudsRayMarchingImageFX")]
public sealed class ImageEffectCloudsRayMarching : PostProcessEffectSettings
{
    [Tooltip("White Noise texture for quick noise lookups."), DisplayName("Noise Texture")]
    public TextureParameter noiseTex = new TextureParameter { value = null }; //TODO: throwing errors if no texture assigned

    [Tooltip("Dimension of noise texture"), DisplayName("Noise Texture Dimension")]
    public FloatParameter noiseTexDimension = new FloatParameter { value = 512f };
}

public sealed class CloudsRayMarchingRenderer : PostProcessEffectRenderer<ImageEffectCloudsRayMarching>
{
    public override void Render(PostProcessRenderContext context)
    {
        var sheet = context.propertySheets.Get(Shader.Find("Custom/CloudsRayMarchingImageFX"));

        sheet.properties.SetFloat("_NoiseTexDimension", settings.noiseTexDimension);
        sheet.properties.SetTexture("_NoiseTex", settings.noiseTex);

        context.command.BlitFullscreenTriangle(context.source, context.destination, sheet, 0);
    }
}