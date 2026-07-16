using UnityEngine;

/// <summary>
/// Spawner de veículos para estrada horizontal.
///
/// COMO USAR:
/// - Crie dois GameObjects: "SpawnerNormal" e "SpawnerContramao"
/// - Adicione este script nos dois e configure no Inspector
/// - Ambos spawnam à direita e movem para a esquerda
/// - A cada spawn o sprite alterna entre normal e espelhado
///
/// PREFAB DE VEÍCULO:
/// - SpriteRenderer + Vehicle.cs
/// - (Opcional) BoxCollider2D com Is Trigger = true
/// </summary>
public class VehicleSpawner : MonoBehaviour
{
    [Header("Veículos")]
    [Tooltip("Arraste aqui todos os prefabs que devem aparecer nesta faixa")]
    public GameObject[] vehiclePrefabs;

    [Header("Velocidade")]
    [Tooltip("Velocidade dos veículos (use valor maior na contramão)")]
    public float speed = 6f;

    [Tooltip("Variação aleatória aplicada à velocidade base (±valor)")]
    public float speedVariance = 1f;

    [Header("Intervalo de Spawn")]
    public float minInterval = 1.5f;
    public float maxInterval = 3.5f;

    [Header("Posição da Faixa")]
    [Tooltip("Posição Y desta faixa na cena")]
    public float laneY = 0f;

    private float timer;
    private float nextSpawnTime;
    private bool flipNext = false; // Alterna a cada spawn

    private void Start()
    {
        ScheduleNextSpawn();
    }

    private void Update()
    {
        timer += Time.deltaTime;

        if (timer >= nextSpawnTime)
        {
            Spawn();
            timer = 0f;
            ScheduleNextSpawn();
        }
    }

    private void Spawn()
    {
        if (vehiclePrefabs == null || vehiclePrefabs.Length == 0)
        {
            Debug.LogWarning($"[VehicleSpawner] '{gameObject.name}' não tem prefabs configurados!", this);
            return;
        }

        GameObject prefab = vehiclePrefabs[Random.Range(0, vehiclePrefabs.Length)];
        if (prefab == null) return;

        float spawnX = GetSpawnX();
        Vector3 spawnPos = new Vector3(spawnX, laneY, 0f);

        GameObject obj = Instantiate(prefab, spawnPos, Quaternion.identity);

        Vehicle vehicle = obj.GetComponent<Vehicle>();
        if (vehicle == null)
        {
            Debug.LogWarning($"[VehicleSpawner] '{prefab.name}' não tem o script Vehicle.cs!", this);
            Destroy(obj);
            return;
        }

        float finalSpeed = speed + Random.Range(-speedVariance, speedVariance);
        vehicle.Setup(finalSpeed, flipNext);

        // Alterna o flip para o próximo spawn
        flipNext = !flipNext;
    }

    private float GetSpawnX()
    {
        Camera cam = Camera.main;
        return cam.orthographicSize * cam.aspect + 1.5f;
    }

    private void ScheduleNextSpawn()
    {
        nextSpawnTime = Random.Range(minInterval, maxInterval);
    }

    private void OnDrawGizmosSelected()
    {
        Camera cam = Camera.main;
        if (cam == null) return;

        float x = GetSpawnX();
        Gizmos.color = Color.cyan;
        Gizmos.DrawLine(new Vector3(x, laneY - 0.5f, 0), new Vector3(x, laneY + 0.5f, 0));
        Gizmos.DrawSphere(new Vector3(x, laneY, 0), 0.15f);
    }
}