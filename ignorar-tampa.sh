#!/bin/bash

# ==============================================================================
# SCRIPT PARA DESABILITAR A SUSPENSÃO AO FECHAR A TAMPA NO UBUNTU SERVER
#
# Este script modifica o /etc/systemd/logind.conf para garantir que as ações
# de fechar a tampa sejam ignoradas, impedindo que o servidor suspenda.
#
# Deve ser executado com privilégios de root (sudo).
# ==============================================================================

# 1. Verificação de Root
# ------------------------------------------------------------------------------
# O script precisa de permissões de root para editar arquivos em /etc/
# e para reiniciar serviços do systemd.
if [ "$EUID" -ne 0 ]; then 
  echo "Erro: Este script precisa ser executado como root."
  echo "Por favor, execute com: sudo ./ignorar_tampa.sh"
  exit 1
fi

# 2. Definição de Variáveis
# ------------------------------------------------------------------------------
CONF_FILE="/etc/systemd/logind.conf"
KEYS_TO_SET=(
    "HandleLidSwitch"
    "HandleLidSwitchExternalPower"
    "HandleLidSwitchDocked"
)
VALUE_TO_SET="ignore"
RESTART_NEEDED=0

echo "Iniciando a configuração de $CONF_FILE..."
echo "------------------------------------------------"

# 3. Criar Backup (por segurança)
# ------------------------------------------------------------------------------
BACKUP_FILE="$CONF_FILE.bak_$(date +%F_%T)"
cp "$CONF_FILE" "$BACKUP_FILE"
echo "-> Backup do arquivo original criado em: $BACKUP_FILE"

# 4. Loop de Configuração
# ------------------------------------------------------------------------------
# Itera sobre cada chave que queremos configurar
for KEY in "${KEYS_TO_SET[@]}"; do
    DESIRED_LINE="$KEY=$VALUE_TO_SET"
    
    # Verifica se a linha exata (descomentada) já existe no arquivo
    if grep -qE "^\s*$DESIRED_LINE" "$CONF_FILE"; then
        echo "-> $KEY já está configurado como '$VALUE_TO_SET'. Pulando."
    else
        echo "-> Configurando $KEY=$VALUE_TO_SET..."
        
        # Se a linha não existe, vamos garantir que qualquer versão antiga
        # (comentada ou com outro valor) seja removida.
        # Usamos '|' como delimitador no sed para evitar conflito com o '/' do path.
        sed -i.bak_sed "\|^#?\s*$KEY=.*|d" "$CONF_FILE"
        
        # Adiciona a linha correta no final do arquivo
        echo "$DESIRED_LINE" >> "$CONF_FILE"
        
        RESTART_NEEDED=1 # Marca que o serviço precisa ser reiniciado
    fi
done

# 5. Reiniciar o Serviço (se necessário)
# ------------------------------------------------------------------------------
if [ $RESTART_NEEDED -eq 1 ]; then
    echo "------------------------------------------------"
    echo "Aplicando as alterações..."
    systemctl restart systemd-logind
    echo "Serviço 'systemd-logind' reiniciado."
else
    echo "------------------------------------------------"
    echo "Nenhuma alteração foi necessária. O sistema já está configurado."
fi

echo ""
echo "Concluído! O servidor agora deve ignorar o fechamento da tampa."
