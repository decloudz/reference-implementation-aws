# HDFS Cluster: ${{ values.clusterName }}

This repository contains the configuration for the HDFS cluster **${{ values.clusterName }}** deployed in the **${{ values.envName }}** environment.

## Cluster Information

- **Cluster Name**: ${{ values.clusterName }}
- **Environment**: ${{ values.envName }}
- **Namespace**: ${{ values.namespace }}
- **HDFS Version**: ${{ values.hdfsVersion }}
- **NameNode Replicas**: ${{ values.nameNodeReplicas }}
- **DataNode Replicas**: ${{ values.dataNodeReplicas }}
- **JournalNode Replicas**: ${{ values.journalNodeReplicas }}

## Configuration

### Storage
- **DataNode Storage per Node**: ${{ values.dataNodeStorageSize }}
- **Storage Class**: ${{ values.storageClass }}
- **Replication Factor**: ${{ values.dfsReplication }}
- **Block Size**: ${{ values.dfsBlockSize }}

### Resources
- **NameNode CPU**: ${{ values.nameNodeCpu }}
- **NameNode Memory**: ${{ values.nameNodeMemory }}
- **DataNode CPU**: ${{ values.dataNodeCpu }}
- **DataNode Memory**: ${{ values.dataNodeMemory }}

### ZooKeeper
- **ZooKeeper Version**: ${{ values.zookeeperVersion }}
- **ZooKeeper Replicas**: ${{ values.zookeeperReplicas }}

### Features
- **High Availability**: ✅ Enabled (Multiple NameNodes with JournalNodes)
- **Advanced Logging**: {% if values.enableLogging %}✅ Enabled (Vector Agent){% else %}❌ Disabled{% endif %}

## Connection Information

### NameNode Services
```
# NameNode Web UI
http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870

# NameNode RPC (for HDFS clients)
${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9820

# NameNode Service RPC
${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:8020
```

### DataNode Services
```
# DataNode Web UI
http://${{ values.clusterName }}-datanode-default.${{ values.namespace }}.svc.cluster.local:9864

# DataNode Data Transfer
${{ values.clusterName }}-datanode-default.${{ values.namespace }}.svc.cluster.local:9866
```

### WebHDFS API
```
# WebHDFS REST API
http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870/webhdfs/v1
```

## Usage Examples

### HDFS Command Line

#### Basic File Operations
```bash
# Create directory
hdfs dfs -mkdir /user/myapp

# Upload file
hdfs dfs -put local-file.txt /user/myapp/

# List files
hdfs dfs -ls /user/myapp

# Download file
hdfs dfs -get /user/myapp/file.txt local-file.txt

# Copy file within HDFS
hdfs dfs -cp /user/myapp/file1.txt /user/myapp/file2.txt

# Remove file
hdfs dfs -rm /user/myapp/file.txt

# Remove directory recursively
hdfs dfs -rm -r /user/myapp
```

#### Advanced Operations
```bash
# Check file system
hdfs fsck /

# Get file system statistics
hdfs dfsadmin -report

# Set replication factor for existing file
hdfs dfs -setrep 2 /user/myapp/file.txt

# Change file permissions
hdfs dfs -chmod 755 /user/myapp/file.txt

# Change file ownership
hdfs dfs -chown myuser:mygroup /user/myapp/file.txt
```

### WebHDFS REST API Examples

#### File Operations via REST
```bash
# Create directory
curl -i -X PUT "http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870/webhdfs/v1/user/myapp?op=MKDIRS"

# Upload file (two-step process)
# Step 1: Get redirect URL
curl -i -X PUT "http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870/webhdfs/v1/user/myapp/file.txt?op=CREATE"

# Step 2: Upload to redirect URL (replace with actual redirect URL from step 1)
curl -i -X PUT -T local-file.txt "http://datanode-url:9864/webhdfs/v1/user/myapp/file.txt?op=CREATE&namenoderpcaddress=..."

# List directory
curl -i "http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870/webhdfs/v1/user/myapp?op=LISTSTATUS"

# Get file status
curl -i "http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870/webhdfs/v1/user/myapp/file.txt?op=GETFILESTATUS"

# Download file
curl -i -L "http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870/webhdfs/v1/user/myapp/file.txt?op=OPEN"

# Delete file
curl -i -X DELETE "http://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:9870/webhdfs/v1/user/myapp/file.txt?op=DELETE"
```

### Java Client Example
```java
// Add dependency: org.apache.hadoop:hadoop-client:${{ values.hdfsVersion }}

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.FileSystem;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.fs.FSDataOutputStream;
import org.apache.hadoop.fs.FSDataInputStream;

Configuration conf = new Configuration();
conf.set("fs.defaultFS", "hdfs://${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local:8020");

FileSystem fs = FileSystem.get(conf);

// Create directory
fs.mkdirs(new Path("/user/myapp"));

// Write file
FSDataOutputStream out = fs.create(new Path("/user/myapp/test.txt"));
out.writeUTF("Hello HDFS!");
out.close();

// Read file
FSDataInputStream in = fs.open(new Path("/user/myapp/test.txt"));
String content = in.readUTF();
System.out.println(content);
in.close();

// List files
FileStatus[] files = fs.listStatus(new Path("/user/myapp"));
for (FileStatus file : files) {
    System.out.println(file.getPath().getName());
}

fs.close();
```

### Python Client Example
```python
# pip install hdfs3 or snakebite-py3

from hdfs3 import HDFileSystem

# Connect to HDFS
hdfs = HDFileSystem(
    host='${{ values.clusterName }}-namenode-default.${{ values.namespace }}.svc.cluster.local',
    port=9820
)

# Create directory
hdfs.mkdir('/user/myapp')

# Write file
with hdfs.open('/user/myapp/test.txt', 'wb') as f:
    f.write(b'Hello HDFS from Python!')

# Read file
with hdfs.open('/user/myapp/test.txt', 'rb') as f:
    content = f.read()
    print(content.decode('utf-8'))

# List files
files = hdfs.ls('/user/myapp')
for file in files:
    print(file)

# File info
info = hdfs.info('/user/myapp/test.txt')
print(f"Size: {info['size']} bytes")
print(f"Replication: {info['replication']}")
```

## Management

### Check Cluster Status
```bash
kubectl get hdfscluster ${{ values.clusterName }} -n ${{ values.namespace }}
kubectl get pods -n ${{ values.namespace }}
kubectl get pvc -n ${{ values.namespace }}
```

### View Component Logs
```bash
# NameNode logs
kubectl logs ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }}

# DataNode logs
kubectl logs ${{ values.clusterName }}-datanode-default-0 -n ${{ values.namespace }}

# JournalNode logs
kubectl logs ${{ values.clusterName }}-journalnode-default-0 -n ${{ values.namespace }}

# ZooKeeper logs
kubectl logs ${{ values.clusterName }}-zk-server-default-0 -n ${{ values.namespace }}
```

### Access Web UIs
```bash
# NameNode Web UI
kubectl port-forward service/${{ values.clusterName }}-namenode-default 9870:9870 -n ${{ values.namespace }}
# Access at http://localhost:9870

# DataNode Web UI
kubectl port-forward service/${{ values.clusterName }}-datanode-default 9864:9864 -n ${{ values.namespace }}
# Access at http://localhost:9864
```

### HDFS Administration
```bash
# Enter NameNode pod for admin commands
kubectl exec -it ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }} -- bash

# Check HDFS health
hdfs dfsadmin -report

# Check file system
hdfs fsck /

# Safe mode operations
hdfs dfsadmin -safemode get
hdfs dfsadmin -safemode leave

# Refresh DataNode list
hdfs dfsadmin -refreshNodes

# Balance cluster
hdfs balancer
```

### Scale Cluster
```bash
# Edit the HdfsCluster resource to change replicas
kubectl edit hdfscluster ${{ values.clusterName }} -n ${{ values.namespace }}
```

## Monitoring

### Key Metrics to Monitor
- **NameNode Health**: Available, standby status
- **DataNode Health**: Live nodes, dead nodes
- **Storage Usage**: DFS used, DFS remaining
- **Block Health**: Under-replicated blocks, corrupt blocks
- **JournalNode Status**: Journal transaction logs

### Health Check Commands
```bash
# Cluster overview
kubectl exec -it ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }} -- hdfs dfsadmin -report

# File system check
kubectl exec -it ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }} -- hdfs fsck / -files -blocks

# NameNode status
kubectl exec -it ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }} -- hdfs haadmin -getAllServiceState
```

## Troubleshooting

### Common Issues

1. **Cluster not ready**
   - Check operator status: `kubectl get pods -n stackable-operators`
   - Check cluster status: `kubectl describe hdfscluster ${{ values.clusterName }} -n ${{ values.namespace }}`
   - Verify ZooKeeper is running: `kubectl get pods -l app.kubernetes.io/name=zookeeper -n ${{ values.namespace }}`

2. **Storage issues**
   - Check PVC status: `kubectl get pvc -n ${{ values.namespace }}`
   - Verify storage class exists: `kubectl get storageclass`
   - Check disk usage: `kubectl exec -it ${{ values.clusterName }}-datanode-default-0 -n ${{ values.namespace }} -- df -h`

3. **NameNode issues**
   - Check NameNode logs: `kubectl logs ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }}`
   - Verify JournalNodes are healthy: `kubectl get pods -l app.kubernetes.io/component=journalnode -n ${{ values.namespace }}`
   - Check safe mode: `kubectl exec -it ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }} -- hdfs dfsadmin -safemode get`

4. **DataNode issues**
   - Check DataNode logs: `kubectl logs ${{ values.clusterName }}-datanode-default-0 -n ${{ values.namespace }}`
   - Verify DataNode registration: `kubectl exec -it ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }} -- hdfs dfsadmin -report`
   - Check network connectivity between nodes

5. **ZooKeeper issues**
   - Check ZooKeeper logs: `kubectl logs ${{ values.clusterName }}-zk-server-default-0 -n ${{ values.namespace }}`
   - Verify ZooKeeper quorum: `kubectl exec -it ${{ values.clusterName }}-zk-server-default-0 -n ${{ values.namespace }} -- zkServer.sh status`

### Performance Tuning

#### DataNode Performance
- Monitor disk I/O and adjust storage class if needed
- Consider SSD storage for better performance
- Monitor network bandwidth between nodes

#### NameNode Performance
- Monitor heap usage and adjust memory if needed
- Consider increasing NameNode memory for large clusters
- Monitor GC performance and tune JVM settings

#### Network Performance
- Ensure adequate network bandwidth between nodes
- Consider rack awareness for better data placement
- Monitor network latency and packet loss

### Recovery Procedures

#### NameNode Recovery
```bash
# If NameNode fails to start, check JournalNode logs
kubectl logs ${{ values.clusterName }}-journalnode-default-0 -n ${{ values.namespace }}

# Format NameNode if needed (WARNING: This will destroy data!)
kubectl exec -it ${{ values.clusterName }}-namenode-default-0 -n ${{ values.namespace }} -- hdfs namenode -format
```

#### DataNode Recovery
```bash
# If DataNode fails to register, restart the pod
kubectl delete pod ${{ values.clusterName }}-datanode-default-0 -n ${{ values.namespace }}

# Check DataNode directory permissions
kubectl exec -it ${{ values.clusterName }}-datanode-default-0 -n ${{ values.namespace }} -- ls -la /stackable/data
```

### Getting Help
- Check ArgoCD application: [HDFS Cluster App](https://cnoe.localtest.me:8443/argocd/applications/argocd/hdfs-${{ values.clusterName }}-${{ values.envName }})
- View configuration: [Repository](https://cnoe.localtest.me:8443/gitea/giteaAdmin/hdfs-${{ values.clusterName }}-${{ values.envName }})
- Contact platform team for support

## References

- [Stackable HDFS Operator Documentation](https://docs.stackable.tech/hdfs/stable/)
- [Apache Hadoop HDFS Documentation](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/HdfsUserGuide.html)
- [HDFS Shell Commands](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-common/FileSystemShell.html)
- [WebHDFS REST API](https://hadoop.apache.org/docs/stable/hadoop-project-dist/hadoop-hdfs/WebHDFS.html)
- [Stackable ZooKeeper Operator](https://docs.stackable.tech/zookeeper/stable/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)