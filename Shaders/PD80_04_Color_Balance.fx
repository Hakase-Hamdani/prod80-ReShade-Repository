/*
    Description : PD80 04 Color Balance for Reshade https://reshade.me/
    Author      : prod80 (Bas Veth)
    License     : MIT, Copyright (c) 2020 prod80


    MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

*/

#include "ReShade.fxh"
#include "ReShadeUI.fxh"

namespace pd80_colorbalance
{
    //// PREPROCESSOR DEFINITIONS ///////////////////////////////////////////////////

    //// UI ELEMENS /////////////////////////////////////////////////////////////////
    uniform bool preserve_luma <
        ui_label = "Preserve Luminosity";
        ui_category = "Color Balance";
    > = true;
    uniform float s_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Shadows:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float s_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Shadows:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float s_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Shadows:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Midtones:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Midtones:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float m_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Midtones:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_RedShift <
        ui_label = "Cyan <--> Red";
        ui_category = "Highlights:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_GreenShift <
        ui_label = "Magenta <--> Green";
        ui_category = "Highlights:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;
    uniform float h_BlueShift <
        ui_label = "Yellow <--> Blue";
        ui_category = "Highlights:";
        ui_type = "slider";
        ui_min = -1.0;
        ui_max = 1.0;
        > = 0.0;

    //// TEXTURES ///////////////////////////////////////////////////////////////////
    texture texColorBuffer : COLOR;
    
    //// SAMPLERS ///////////////////////////////////////////////////////////////////
    sampler samplerColor { Texture = texColorBuffer; };

    //// DEFINES ////////////////////////////////////////////////////////////////////
    #define ES_RGB   float3( 1.0 - float3( 0.299, 0.587, 0.114 ))
    #define ES_CMY   float3( dot( ES_RGB.yz, 0.5 ), dot( ES_RGB.xz, 0.5 ), dot( ES_RGB.xy, 0.5 ))

    //// FUNCTIONS //////////////////////////////////////////////////////////////////
    float3 curve( float3 x )
    {
        return x * x * x * ( x * ( x * 6.0f - 15.0f ) + 10.0f );
    }

    float3 ColorBalance( float3 c, float3 shadows, float3 midtones, float3 highlights )
    {
        // For highlights
        float luma   = dot( c.xyz, 0.333f );
        
        // Determine the distribution curves between shadows, midtones, and highlights
        float3 dist_s= curve( max( 1.0f - c.xyz * 2.0f, 0.0f ));
        float3 dist_h= curve( max(( c.xyz - 0.5f ) * 2.0f, 0.0f ));

        // Get luminosity offsets
        // One could omit this whole code part in case no luma should be preserved
        float3 s_rgb = 1.0f;
        float3 m_rgb = 1.0f;
        float3 h_rgb = 1.0f;

        if( preserve_luma )
        {
            s_rgb    = shadows > 0.0f     ? ES_RGB * shadows      : ES_CMY * abs( shadows );
            m_rgb    = midtones > 0.0f    ? ES_RGB * midtones     : ES_CMY * abs( midtones );
            h_rgb    = highlights > 0.0f  ? ES_RGB * highlights   : ES_CMY * abs( highlights );
        }
        float3 mids  = saturate( 1.0f - dist_s.xyz - dist_h.xyz );
        float3 highs = dist_h.xyz * ( highlights.xyz * h_rgb.xyz * ( 1.0f - luma ));
        float3 newc  = c.xyz * ( dist_s.xyz * shadows.xyz * s_rgb.xyz + mids.xyz * midtones.xyz * m_rgb.xyz ) * ( 1.0f - c.xyz ) + highs.xyz;
        return saturate( c.xyz + newc.xyz );
    }

    //// PIXEL SHADERS //////////////////////////////////////////////////////////////
    float4 PS_ColorBalance(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
    {
        float4 color      = tex2D( samplerColor, texcoord );
        color.xyz         = ColorBalance( color.xyz, float3( s_RedShift, s_GreenShift, s_BlueShift ), 
                                                     float3( m_RedShift, m_GreenShift, m_BlueShift ),
                                                     float3( h_RedShift, h_GreenShift, h_BlueShift ));
        return float4( color.xyz, 1.0f );
    }

    //// TECHNIQUES /////////////////////////////////////////////////////////////////
    technique prod80_04_ColorBalance
    {
        pass prod80_pass0
        {
            VertexShader   = PostProcessVS;
            PixelShader    = PS_ColorBalance;
        }
    }
}


