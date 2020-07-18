using System.Collections.Generic;
using System.Linq;
using UnityEngine;

class RippleCollisionInstance
{
    public float waveAmplitude { get; set; }
    public float offsetX { get; set; }
    public float offsetZ { get; set; }
    public float distance { get; set; }
    public float impactX { get; set; }
    public float impactZ { get; set; }
}
public class RippleCollision : MonoBehaviour
{
    private readonly int maxWaves = 100;
    private int wIndex;
    public float distanceX, distanceZ;
    public float magnitudeDivider;
    public float speedWaveSpread;

    public float[] waveAmplitude;
    public float[] offsetX;
    public float[] offsetZ;
    public Vector2[] impactPos;

    List<RippleCollisionInstance> rippleCollisions;

    Mesh mesh;
    // Start is called before the first frame update
    void Start()
    {
        wIndex = 0;
        mesh = GetComponent<MeshFilter>().mesh;
        rippleCollisions = new List<RippleCollisionInstance>(maxWaves);

        for (int i = 0; i < maxWaves; i++)
        {
            rippleCollisions.Add(new RippleCollisionInstance());
        }
    }

    // Update is called once per frame
    void Update()
    {
        if (rippleCollisions.Count == 0 || wIndex == 0)
        {
            return;
        }

        

        waveAmplitude = GetComponent<Renderer>().material.GetFloatArray($"_WaveAmplitude");
        for (int i=0; i<waveAmplitude.Length; i++)
        {
            if (waveAmplitude[i] > 0)
            {
                rippleCollisions[i].distance += speedWaveSpread;
                rippleCollisions[i].waveAmplitude = waveAmplitude[i] * 0.98f;
            }
            if (waveAmplitude[i] < 0.01)
            {
                rippleCollisions[i].waveAmplitude = 0;
            }
        }

        int count = rippleCollisions.Count;

        GetComponent<Renderer>().material.SetFloat($"_DistanceArray", count);
        GetComponent<Renderer>().material.SetFloatArray($"_Distance", rippleCollisions.Select(rc => rc.distance).ToArray());

        GetComponent<Renderer>().material.SetFloat($"_WaveAmplitudeArray", count);
        GetComponent<Renderer>().material.SetFloatArray($"_WaveAmplitude", rippleCollisions.Select(rc => rc.waveAmplitude).ToArray());
    }

    private void OnTriggerStay(Collider collider)
    {
        if (collider.gameObject.GetComponent<Rigidbody>())
        {
            RippleCollisionInstance rippleCollision = new RippleCollisionInstance();

            if (wIndex == maxWaves) // if this is the last allowed wave, go back to the first wave.
            {
                wIndex = 0;
            }

            rippleCollision.waveAmplitude = 0;
            rippleCollision.distance = 0;

            distanceX = this.transform.position.x - collider.gameObject.transform.position.x;
            distanceZ = this.transform.position.z - collider.gameObject.transform.position.z;

            rippleCollision.impactX = collider.transform.position.x;
            rippleCollision.impactZ = collider.transform.position.z;

            rippleCollision.offsetX = distanceX / mesh.bounds.size.x * 2.5f;
            rippleCollision.offsetZ = distanceZ / mesh.bounds.size.z * 2.5f;

            float velocity = collider.gameObject.GetComponent<Rigidbody>().velocity.magnitude;
            velocity = velocity > 0 ? velocity : 0.1f; 
            rippleCollision.waveAmplitude = velocity / 2 * collider.gameObject.GetComponent<Rigidbody>().mass * magnitudeDivider;

            rippleCollisions[wIndex] = rippleCollision;

            int count = rippleCollisions.Count;

            GetComponent<Renderer>().material.SetFloat($"_xImpactArray", count);
            GetComponent<Renderer>().material.SetFloatArray($"_xImpact", rippleCollisions.Select(rc => rc.impactX).ToArray());

            GetComponent<Renderer>().material.SetFloat($"_zImpactArray", count);
            GetComponent<Renderer>().material.SetFloatArray($"_zImpact", rippleCollisions.Select(rc => rc.impactZ).ToArray());

            GetComponent<Renderer>().material.SetFloat($"_OffsetXArray", count);
            GetComponent<Renderer>().material.SetFloatArray($"_OffsetX", rippleCollisions.Select(rc => rc.offsetX).ToArray());

            GetComponent<Renderer>().material.SetFloat($"_OffsetZArray", count);
            GetComponent<Renderer>().material.SetFloatArray($"_OffsetZ", rippleCollisions.Select(rc => rc.offsetZ).ToArray());

            GetComponent<Renderer>().material.SetFloat($"_WaveAmplitudeArray", count);
            GetComponent<Renderer>().material.SetFloatArray($"_WaveAmplitude", rippleCollisions.ToList().Select(rc => rc.waveAmplitude).ToArray());

            wIndex++;
        }
    }
}
