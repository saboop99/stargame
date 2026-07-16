using Unity.VisualScripting;
using UnityEngine;

public class Score: MonoBehaviour
{
    public int score;
    public float pointsPerSecond = 10f;
    public bool isScoring = true;

    private void Start()
    {
       
    }

    private void Update()
    {
        if (isScoring)
        {
            score += (int)(pointsPerSecond * Time.deltaTime);
        }
    }

    public void StopScoring()
    {
        isScoring = false;
    }
}
