using UnityEngine;
using System.Collections;

public class WobbleValue : MonoBehaviour 
{
    public int MaterialIndex = 0;
    public float Speed = 1.0f;
	public float Multiply = 64.0f;
	public float Offset = 32.0f;
    public string ValueName = "_Distort";

    void LateUpdate() 
    {
        if( renderer.enabled )
            renderer.materials[MaterialIndex].SetFloat( ValueName, Offset + Mathf.Sin( Time.time * Speed ) * Multiply );
    }
}