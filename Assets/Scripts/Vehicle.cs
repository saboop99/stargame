using UnityEngine;

/// <summary>
/// Coloque este script em cada prefab de veículo.
/// O spawner define velocidade e se o sprite deve ser espelhado.
/// </summary>
public class Vehicle : MonoBehaviour
{
    private float speed;

    public void Setup(float vehicleSpeed, bool flipSprite)
    {
        speed = vehicleSpeed;

        if (flipSprite)
        {
            Vector3 s = transform.localScale;
            s.x *= -1f;
            transform.localScale = s;
        }
    }

    private void Update()
    {
        transform.Translate(Vector2.left * speed * Time.deltaTime);

        if (IsOffScreen())
            Destroy(gameObject);
    }

    private bool IsOffScreen()
    {
        Camera cam = Camera.main;
        if (cam == null) return false;

        float halfWidth = cam.orthographicSize * cam.aspect + 2f;
        return transform.position.x < -halfWidth;
    }
}